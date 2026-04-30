package com.sawitku.dto.response;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PanenResponse {
    private Long id;
    private Long lahanId;
    private String namaLahan;
    private java.math.BigDecimal luasHa;
    private Integer usiaPohon;
    private String bulan;
    private Integer tahun;
    private Integer bulanAngka;
    private Integer tanggal;
    private BigDecimal tonAktual;
    private BigDecimal targetMin;
    private BigDecimal targetMax;
    private BigDecimal targetMid;
    private String statusPanen;
    private BigDecimal persenKurang;
    private BigDecimal hargaPerTon;
    private BigDecimal nilaiEstimasi;
    private String catatan;
    private LocalDateTime createdAt;
    private AnalisaResponse analisa;
}
