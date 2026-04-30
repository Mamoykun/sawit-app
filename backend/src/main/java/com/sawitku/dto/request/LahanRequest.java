package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class LahanRequest {
    @NotBlank @Size(max=100) public String namaLahan;
    @NotNull @Positive public BigDecimal luasHa;
    // Salah satu wajib diisi: tahunTanam atau usiaPohon
    public Integer tahunTanam;
    public Integer usiaPohon;
    public Integer jumlahPohon;
    @Size(max=255) public String lokasi;
    public BigDecimal latitude;
    public BigDecimal longitude;
    public String catatan;
}
