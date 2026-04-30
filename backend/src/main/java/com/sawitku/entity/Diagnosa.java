package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "diagnosa")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Diagnosa {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lahan_id", nullable = false)
    private Lahan lahan;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private JenisDiagnosa jenis;

    @Column(name = "image_base64", nullable = false, columnDefinition = "TEXT")
    private String imageBase64;

    @Column(columnDefinition = "TEXT")
    private String kondisi;

    @Column(columnDefinition = "TEXT")
    private String penyebab;

    @Column(columnDefinition = "TEXT")
    private String rekomendasi;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SeverityDiagnosa severity;

    @Column(name = "is_fallback")
    private Boolean isFallback;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
