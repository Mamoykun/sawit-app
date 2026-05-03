package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import java.time.Instant;
import java.time.LocalDateTime;

/**
 * Progress photos for a lahan, grouped by month.
 * Files are stored on local disk under uploads/photos/{lahanId}/{uuid}.jpg
 * and served via Spring's static resource handler mapped to /photos/**.
 */
@Entity
@Table(name = "lahan_photos")
@SQLDelete(sql = "UPDATE lahan_photos SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?")
@SQLRestriction("deleted_at IS NULL")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class LahanPhoto {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lahan_id", nullable = false)
    private Lahan lahan;

    @Column(name = "image_url", nullable = false, length = 500)
    private String imageUrl;

    @Column(length = 500)
    private String caption;

    @Column(name = "taken_at", nullable = false)
    private LocalDateTime takenAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(length = 20)
    private String bulan;

    @Column
    private Integer tahun;

    @Column(name = "bulan_angka")
    private Integer bulanAngka;
}
