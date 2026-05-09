package com.sawitku.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class FeedbackRequest {

    @NotBlank
    private String type;

    @NotBlank
    @Size(max = 200)
    private String subject;

    @NotBlank
    @Size(min = 10, max = 2000)
    private String detail;

    @Email
    private String userEmail;
}
