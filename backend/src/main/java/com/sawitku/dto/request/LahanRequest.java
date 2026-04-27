package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class LahanRequest {
    @NotBlank @Size(max=100) public String namaLahan;
    @NotNull @Positive public BigDecimal luasHa;
    @NotNull @Min(1) @Max(50) public Integer usiaPohon;
    public Integer jumlahPohon;
    @Size(max=255) public String lokasi;
    public BigDecimal latitude;
    public BigDecimal longitude;
    public String catatan;
}
