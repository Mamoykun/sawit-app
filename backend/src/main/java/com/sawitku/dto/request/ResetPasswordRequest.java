package com.sawitku.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ResetPasswordRequest {
    @NotBlank
    private String token;

    @NotBlank @Size(min = 8, message = "Password minimal 8 karakter")
    private String newPassword;
}
