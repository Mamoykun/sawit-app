package com.sawitku.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.dto.request.CreatePaymentRequest;
import com.sawitku.dto.response.PaymentResponse;
import com.sawitku.entity.*;
import com.sawitku.exception.BusinessException;
import com.sawitku.exception.ResourceNotFoundException;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.PaymentRepository;
import com.sawitku.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.*;

/// Midtrans Snap API integration for subscription upgrades.
///
/// Flow:
///  1. Frontend POST /api/payments/create with {targetPaket, durationMonths}
///  2. PaymentService creates Payment entity (status=PENDING) + calls Snap API
///  3. Returns snapToken + snapUrl → frontend opens Snap WebView
///  4. User pays via Midtrans-hosted page (any method)
///  5. Midtrans POSTs to /api/payments/notification (webhook)
///  6. PaymentService verifies signature, updates status, extends Subscription
@Service
@Slf4j
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final ObjectMapper objectMapper;
    private final AuditService auditService;

    @Value("${midtrans.server-key:}")
    private String serverKey;

    @Value("${midtrans.client-key:}")
    private String clientKey;

    @Value("${midtrans.is-production:false}")
    private boolean isProduction;

    @Value("${app.subscription.price-petani:25000}")
    private int pricePetani;

    @Value("${app.subscription.price-pro:75000}")
    private int pricePro;

    private String snapApiUrl() {
        return isProduction
            ? "https://app.midtrans.com/snap/v1/transactions"
            : "https://app.sandbox.midtrans.com/snap/v1/transactions";
    }

    public String getClientKey() { return clientKey; }

    @Transactional
    public PaymentResponse createPayment(User user, CreatePaymentRequest req) {
        if (req.getTargetPaket() == PaketSubscription.GRATIS) {
            throw new BusinessException("Tidak bisa beli paket GRATIS", "INVALID_PAKET");
        }
        BigDecimal monthly = switch (req.getTargetPaket()) {
            case PETANI -> BigDecimal.valueOf(pricePetani);
            case PRO -> BigDecimal.valueOf(pricePro);
            case GRATIS -> null;
        };
        if (monthly == null) {
            throw new BusinessException("Paket tidak valid", "INVALID_PAKET");
        }
        BigDecimal grossAmount = monthly.multiply(BigDecimal.valueOf(req.getDurationMonths()));

        // Build orderId — format: SAWIT-{userId}-{timestamp}
        String orderId = "SAWIT-" + user.getId() + "-" + System.currentTimeMillis();

        Payment payment = Payment.builder()
            .user(user)
            .orderId(orderId)
            .targetPaket(req.getTargetPaket())
            .durationMonths(req.getDurationMonths())
            .grossAmount(grossAmount)
            .status(PaymentStatus.PENDING)
            .createdAt(LocalDateTime.now())
            .expiredAt(LocalDateTime.now().plusHours(24))
            .build();
        paymentRepository.save(payment);

        try { auditService.log(AuditAction.PAYMENT_CREATE, user.getId(), "Payment", payment.getId(),
                Map.of("orderId", orderId, "paket", req.getTargetPaket().name(),
                        "grossAmount", grossAmount.toString())); }
        catch (Exception ignored) {}

        // Call Midtrans Snap API
        try {
            Map<String, Object> snap = callMidtransSnap(payment, user);
            payment.setSnapToken((String) snap.get("token"));
            payment.setSnapUrl((String) snap.get("redirect_url"));
            payment.setMidtransResponse(objectMapper.writeValueAsString(snap));
            paymentRepository.save(payment);
        } catch (Exception e) {
            log.error("Midtrans Snap API error for orderId {}: {}", orderId, e.getMessage());
            payment.setStatus(PaymentStatus.FAILED);
            paymentRepository.save(payment);
            throw new BusinessException(
                "Gagal terhubung ke gateway pembayaran. Coba lagi nanti.",
                "PAYMENT_GATEWAY_ERROR");
        }

        return toResponse(payment);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> callMidtransSnap(Payment payment, User user) {
        if (serverKey == null || serverKey.isBlank()) {
            throw new BusinessException(
                "Gateway pembayaran belum dikonfigurasi (admin: set MIDTRANS_SERVER_KEY).",
                "PAYMENT_NOT_CONFIGURED");
        }

        RestTemplate rest = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));

        // Midtrans auth: Basic base64(serverKey + ":")
        String auth = Base64.getEncoder().encodeToString(
            (serverKey + ":").getBytes(StandardCharsets.UTF_8));
        headers.set("Authorization", "Basic " + auth);

        String paketName = payment.getTargetPaket().name();
        String itemName = "SawitKu " + paketName + " (" + payment.getDurationMonths() + " bulan)";

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("transaction_details", Map.of(
            "order_id", payment.getOrderId(),
            "gross_amount", payment.getGrossAmount().longValue()
        ));
        body.put("customer_details", Map.of(
            "first_name", user.getName() != null ? user.getName() : "Pengguna",
            "email", user.getEmail() != null ? user.getEmail() : "no-email@sawitku.id",
            "phone", user.getPhone() != null ? user.getPhone() : ""
        ));
        body.put("item_details", List.of(Map.of(
            "id", "PAKET_" + paketName,
            "name", itemName,
            "price", payment.getGrossAmount().longValue(),
            "quantity", 1
        )));
        // Auto-expire snap token in 24 hours
        body.put("expiry", Map.of(
            "unit", "hours",
            "duration", 24
        ));

        try {
            ResponseEntity<Map> response = rest.exchange(
                snapApiUrl(),
                HttpMethod.POST,
                new HttpEntity<>(body, headers),
                Map.class);
            return (Map<String, Object>) response.getBody();
        } catch (RestClientException e) {
            log.error("Midtrans Snap call failed: {}", e.getMessage());
            throw new RuntimeException("Snap API call failed", e);
        }
    }

    /**
     * Verifies the Midtrans webhook signature to prevent forged payment notifications.
     *
     * <p>Midtrans signature formula (from docs):
     * {@code SHA512(order_id + status_code + gross_amount + serverKey)}
     *
     * @param notification the raw webhook body map
     * @return {@code true} if the computed signature matches the one in the payload
     */
    private boolean verifySignature(Map<String, Object> notification) {
        String orderId      = (String) notification.get("order_id");
        String statusCode   = (String) notification.get("status_code");
        String grossAmount  = (String) notification.get("gross_amount");
        String signatureKey = (String) notification.get("signature_key");

        if (orderId == null || statusCode == null || grossAmount == null || signatureKey == null) {
            log.warn("Midtrans webhook missing fields required for signature check");
            return false;
        }
        if (serverKey == null || serverKey.isBlank()) {
            // No server key configured — skip verification in dev, warn loudly
            log.warn("MIDTRANS_SERVER_KEY not configured — skipping signature verification (dev mode only)");
            return true;
        }

        String payload = orderId + statusCode + grossAmount + serverKey;
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-512");
            byte[] digest = md.digest(payload.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString().equals(signatureKey);
        } catch (NoSuchAlgorithmException e) {
            // SHA-512 is mandated by JDK spec — this cannot happen in practice
            log.error("SHA-512 algorithm unavailable", e);
            return false;
        }
    }

    /// Webhook handler — called by Midtrans on payment status change.
    /// Idempotent: same notification can be received multiple times.
    @Transactional
    public void handleNotification(Map<String, Object> notification) {
        // --- SECURITY: verify Midtrans signature before any DB writes ---
        if (!verifySignature(notification)) {
            log.warn("Midtrans webhook REJECTED — invalid signature for order_id={}",
                notification.get("order_id"));
            return; // Return silently so Midtrans does not retry a legitimately bad request
        }

        String orderId = (String) notification.get("order_id");
        String txStatus = (String) notification.get("transaction_status");
        String fraudStatus = (String) notification.get("fraud_status");
        String paymentType = (String) notification.get("payment_type");

        if (orderId == null) {
            log.warn("Webhook missing order_id");
            return;
        }

        Payment payment = paymentRepository.findByOrderId(orderId)
            .orElseThrow(() -> new ResourceNotFoundException("Payment not found: " + orderId));

        // Already finalized — idempotency
        if (payment.getStatus() == PaymentStatus.PAID) {
            log.info("Webhook for already-paid order {}, ignoring", orderId);
            return;
        }

        // Parse Midtrans status to internal status
        PaymentStatus newStatus = parseStatus(txStatus, fraudStatus);
        payment.setStatus(newStatus);
        payment.setPaymentMethod(paymentType);
        try {
            payment.setMidtransResponse(objectMapper.writeValueAsString(notification));
        } catch (Exception ignored) {}

        if (newStatus == PaymentStatus.PAID) {
            payment.setPaidAt(LocalDateTime.now());
            // Extend subscription
            extendSubscription(payment);
        }
        paymentRepository.save(payment);

        try {
            Long userId = payment.getUser() != null ? payment.getUser().getId() : null;
            auditService.log(AuditAction.PAYMENT_STATUS_CHANGE, userId, "Payment", payment.getId(),
                    Map.of("orderId", orderId, "newStatus", newStatus.name()));
        } catch (Exception ignored) {}
    }

    private PaymentStatus parseStatus(String txStatus, String fraudStatus) {
        if (txStatus == null) return PaymentStatus.PENDING;
        return switch (txStatus.toLowerCase()) {
            case "capture" -> "challenge".equalsIgnoreCase(fraudStatus)
                ? PaymentStatus.PENDING : PaymentStatus.PAID;
            case "settlement" -> PaymentStatus.PAID;
            case "pending" -> PaymentStatus.PENDING;
            case "deny", "failure" -> PaymentStatus.FAILED;
            case "expire" -> PaymentStatus.EXPIRED;
            case "cancel" -> PaymentStatus.CANCELLED;
            default -> PaymentStatus.PENDING;
        };
    }

    private void extendSubscription(Payment payment) {
        Long userId = payment.getUser().getId();
        Subscription sub = subscriptionRepository.findByUserId(userId)
            .orElseGet(() -> Subscription.builder()
                .user(payment.getUser())
                .paket(PaketSubscription.GRATIS)
                .status("ACTIVE")
                .createdAt(LocalDateTime.now())
                .build());

        // If existing subscription is still active and same paket, extend from current expiry.
        // Otherwise extend from now.
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime base = (sub.getExpiredAt() != null
                && sub.getExpiredAt().isAfter(now)
                && sub.getPaket() == payment.getTargetPaket())
            ? sub.getExpiredAt()
            : now;
        sub.setPaket(payment.getTargetPaket());
        sub.setStatus("ACTIVE");
        sub.setExpiredAt(base.plusMonths(payment.getDurationMonths()));
        subscriptionRepository.save(sub);
        log.info("Subscription extended for user {} to {} until {}",
            userId, sub.getPaket(), sub.getExpiredAt());
    }

    public List<PaymentResponse> getMyPayments(Long userId) {
        return paymentRepository.findByUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toResponse).toList();
    }

    public PaymentResponse getPaymentByOrderId(Long userId, String orderId) {
        Payment p = paymentRepository.findByOrderId(orderId)
            .orElseThrow(() -> new ResourceNotFoundException("Payment tidak ditemukan"));
        if (!p.getUser().getId().equals(userId)) {
            throw new ResourceNotFoundException("Payment tidak ditemukan");
        }
        return toResponse(p);
    }

    private PaymentResponse toResponse(Payment p) {
        return PaymentResponse.builder()
            .id(p.getId())
            .orderId(p.getOrderId())
            .targetPaket(p.getTargetPaket().name())
            .durationMonths(p.getDurationMonths())
            .grossAmount(p.getGrossAmount())
            .status(p.getStatus().name())
            .paymentMethod(p.getPaymentMethod())
            .snapToken(p.getSnapToken())
            .snapUrl(p.getSnapUrl())
            .paidAt(p.getPaidAt())
            .createdAt(p.getCreatedAt())
            .build();
    }
}
