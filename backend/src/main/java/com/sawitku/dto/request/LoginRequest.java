package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
@Data
public class LoginRequest {
    @NotBlank @Email public String email;
    @NotBlank @Size(min = 8) public String password;
}
