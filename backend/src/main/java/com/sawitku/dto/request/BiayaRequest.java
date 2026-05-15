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
    @NotNull @DecimalMin(value = "0", message = "Jumlah biaya tidak boleh negatif") public BigDecimal jumlah;
    public String keterangan;
}
