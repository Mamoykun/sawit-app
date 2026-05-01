package com.sawitku.dto.request;

import com.sawitku.entity.PaketSubscription;
import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class CreatePaymentRequest {
    @NotNull
    public PaketSubscription targetPaket; // PETANI atau PRO (tidak boleh GRATIS)

    @NotNull @Min(1) @Max(12)
    public Integer durationMonths;
}
