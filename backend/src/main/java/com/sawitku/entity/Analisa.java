package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "analisa")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Analisa {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "panen_id", nullable = false)
    private Panen panen;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lahan_id", nullable = false)
    private Lahan lahan;

    @Column(name = "penyebab_json", columnDefinition = "JSONB")
    private String penyebabJson;

    @Column(columnDefinition = "TEXT")
    private String rekomendasi;

    @Column(name = "ai_response_raw", columnDefinition = "TEXT")
    private String aiResponseRaw;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
