package com.sawitku.dto.response;

import lombok.*;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TokenResponse {
    private String token;
    private String refreshToken;
}
