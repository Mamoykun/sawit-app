package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class PanenRequest {
    @NotBlank @Size(max=20) public String bulan;
    @NotNull @Min(2020) @Max(2100) public Integer tahun;
    @NotNull @Min(1) @Max(12) public Integer bulanAngka;
    @Min(1) @Max(31) public Integer tanggal;
    @NotNull @DecimalMin(value = "0.01", message = "Ton aktual harus lebih dari 0") public BigDecimal tonAktual;
    @DecimalMin(value = "0", message = "Harga per ton tidak boleh negatif") public BigDecimal hargaPerTon;
    public String catatan;
}
