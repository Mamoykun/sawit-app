package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "ai_usage")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class AiUsage {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Format: YYYY-MM (e.g. 2025-06) */
    @Column(nullable = false, length = 7)
    private String period;

    @Column(nullable = false, length = 32)
    private String model;

    @Column(name = "input_tokens", nullable = false)
    private Integer inputTokens;

    @Column(name = "output_tokens", nullable = false)
    private Integer outputTokens;

    @Column(name = "cost_usd_cents", nullable = false)
    private Integer costUsdCents;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }
}
