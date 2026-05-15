package com.sawitku.controller;

import com.sawitku.dto.request.CreatePaymentRequest;
import com.sawitku.dto.response.ApiResponse;
import com.sawitku.dto.response.PaymentResponse;
import com.sawitku.entity.User;
import com.sawitku.service.PaymentService;
import com.sawitku.util.ResponseUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
@Slf4j
public class PaymentController {

    private final PaymentService paymentService;

    /// Create new payment intent → returns Snap token + URL.
    /// Frontend opens snapUrl in WebView so user can pay.
    @PostMapping("/create")
    public ResponseEntity<ApiResponse<PaymentResponse>> create(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody CreatePaymentRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ResponseUtil.ok(paymentService.createPayment(user, req),
                "Pembayaran dibuat, silakan selesaikan di Midtrans").getBody());
    }

    /// Webhook from Midtrans — public endpoint (no auth).
    /// SecurityConfig must permit "/api/payments/notification".
    /// Idempotent: same notification can arrive multiple times.
    @PostMapping("/notification")
    public ResponseEntity<Map<String, String>> notification(
            @RequestBody Map<String, Object> notification,
            HttpServletRequest request) {
        String clientIp = resolveClientIp(request);
        log.info("Midtrans webhook received from {}: order_id={}, status={}",
            clientIp, notification.get("order_id"), notification.get("transaction_status"));
        try {
            paymentService.handleNotification(notification);
            return ResponseEntity.ok(Map.of("status", "ok"));
        } catch (Exception e) {
            log.error("Webhook processing error from {}: {}", clientIp, e.getMessage(), e);
            // Return 200 anyway — Midtrans will retry on non-200, we don't want infinite loop
            return ResponseEntity.ok(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    /// Get payment history of current user.
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<List<PaymentResponse>>> myPayments(
            @AuthenticationPrincipal User user) {
        return ResponseUtil.ok(paymentService.getMyPayments(user.getId()));
    }

    /// Get specific payment by orderId (for checking status after WebView returns).
    @GetMapping("/order/{orderId}")
    public ResponseEntity<ApiResponse<PaymentResponse>> getByOrderId(
            @AuthenticationPrincipal User user,
            @PathVariable String orderId) {
        return ResponseUtil.ok(paymentService.getPaymentByOrderId(user.getId(), orderId));
    }

    /// Public endpoint to expose Midtrans config (client key + mode) for frontend.
    /// Useful if frontend wants to use Midtrans Snap.js directly (not WebView).
    @GetMapping("/config")
    public ResponseEntity<ApiResponse<Map<String, Object>>> config() {
        return ResponseUtil.ok(Map.of(
            "clientKey", paymentService.getClientKey(),
            "pricing", Map.of(
                "PETANI", 25000,
                "PRO", 75000
            )
        ));
    }
}
