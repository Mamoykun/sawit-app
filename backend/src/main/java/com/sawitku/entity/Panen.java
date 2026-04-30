package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "panen")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Panen {

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

    @Column
    private Integer tanggal;

    @Column(name = "ton_aktual", nullable = false, precision = 8, scale = 2)
    private BigDecimal tonAktual;

    @Column(name = "target_min", nullable = false, precision = 8, scale = 2)
    private BigDecimal targetMin;

    @Column(name = "target_max", nullable = false, precision = 8, scale = 2)
    private BigDecimal targetMax;

    @Column(name = "target_mid", nullable = false, precision = 8, scale = 2)
    private BigDecimal targetMid;

    @Enumerated(EnumType.STRING)
    @Column(name = "status_panen", nullable = false)
    private StatusPanen statusPanen;

    @Column(name = "persen_kurang", precision = 5, scale = 2)
    private BigDecimal persenKurang;

    @Column(name = "harga_per_ton", precision = 12, scale = 2)
    private BigDecimal hargaPerTon;

    @Column(columnDefinition = "TEXT")
    private String catatan;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @OneToOne(mappedBy = "panen", cascade = CascadeType.ALL)
    private Analisa analisa;
}
