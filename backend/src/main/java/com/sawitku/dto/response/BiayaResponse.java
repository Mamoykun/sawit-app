package com.sawitku.dto.response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class BiayaResponse {
    private Long id;
    private Long lahanId;
    private String bulan;
    private Integer tahun;
    private Integer bulanAngka;
    private String kategori;
    private BigDecimal jumlah;
    private String keterangan;
    private LocalDateTime createdAt;
}
