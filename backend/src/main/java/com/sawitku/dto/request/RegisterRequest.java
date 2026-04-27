package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
@Data
public class RegisterRequest {
    @NotBlank @Size(max=100) public String name;
    @NotBlank @Email @Size(max=100) public String email;
    @NotBlank @Size(min=6, max=100) public String password;
    @Size(max=20) public String phone;
}
