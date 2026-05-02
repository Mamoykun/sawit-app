package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;

@Entity
@Table(name = "biaya")
@SQLDelete(sql = "UPDATE biaya SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?")
@SQLRestriction("deleted_at IS NULL")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Biaya {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lahan_id", nullable = false)
    private Lahan lahan;

    @Column(nullable = false, length = 20)
    private String bulan;

    @Column(nullable = false)
    private Integer tahun;

    @Column(name = "bulan_angka", nullable = false)
    private Integer bulanAngka;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private KategoriBiaya kategori;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal jumlah;

    @Column(columnDefinition = "TEXT")
    private String keterangan;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;
}
