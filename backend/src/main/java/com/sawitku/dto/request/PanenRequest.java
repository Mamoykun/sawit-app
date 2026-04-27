package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class PanenRequest {
    @NotBlank @Size(max=20) public String bulan;
    @NotNull @Min(2020) @Max(2100) public Integer tahun;
    @NotNull @Min(1) @Max(12) public Integer bulanAngka;
    @NotNull @Positive public BigDecimal tonAktual;
    public BigDecimal hargaPerTon;
    public String catatan;
}
