package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class LahanRequest {
    @NotBlank @Size(max=100) public String namaLahan;
    @NotNull @DecimalMin("0.1") @DecimalMax("10000") public BigDecimal luasHa;
    // Salah satu wajib diisi: tahunTanam atau usiaPohon
    @Min(1900) @Max(2100) public Integer tahunTanam;
    @Min(1) @Max(200) public Integer usiaPohon;
    @Min(1) public Integer jumlahPohon;
    @Size(max=255) public String lokasi;
    public BigDecimal latitude;
    public BigDecimal longitude;
    public String catatan;
}
