package com.sawitku.dto.response;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class LahanResponse {
    private Long id;
    private String namaLahan;
    private BigDecimal luasHa;
    private Integer usiaPohon;
    private Integer tahunTanam;
    private Integer jumlahPohon;
    private String lokasi;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String catatan;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private PanenSummary panenTerakhir;
    private String statusTerkini;
    private String faseProduksi;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class PanenSummary {
        private Long id;
        private String bulan;
        private Integer tahun;
        private BigDecimal tonAktual;
        private BigDecimal targetMid;
        private String statusPanen;
        private BigDecimal persenKurang;
    }
}
