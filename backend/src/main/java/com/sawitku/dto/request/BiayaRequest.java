package com.sawitku.dto.request;

import com.sawitku.entity.KategoriBiaya;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class BiayaRequest {
    @NotBlank @Size(max = 20) public String bulan;
    @NotNull @Min(2020) @Max(2100) public Integer tahun;
    @NotNull @Min(1) @Max(12) public Integer bulanAngka;
    @NotNull public KategoriBiaya kategori;
    @NotNull @Positive public BigDecimal jumlah;
    public String keterangan;
}
