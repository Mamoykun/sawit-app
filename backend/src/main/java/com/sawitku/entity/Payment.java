package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Payment {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /// Order ID format: SAWIT-{userId}-{epochMillis}
    /// Used as Midtrans transaction ID and webhook lookup key.
    @Column(name = "order_id", nullable = false, unique = true, length = 64)
    private String orderId;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_paket", nullable = false, length = 20)
    private PaketSubscription targetPaket;

    @Column(name = "duration_months", nullable = false)
    private Integer durationMonths;

    @Column(name = "gross_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal grossAmount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PaymentStatus status;

    @Column(name = "payment_method", length = 40)
    private String paymentMethod;

    @Column(name = "snap_token", length = 255)
    private String snapToken;

    @Column(name = "snap_url", length = 500)
    private String snapUrl;

    @Column(name = "midtrans_response", columnDefinition = "TEXT")
    private String midtransResponse;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "expired_at")
    private LocalDateTime expiredAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
