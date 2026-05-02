package com.sawitku.dto.request;

import lombok.Data;

@Data
public class LogoutRequest {
    /** If present, revoke only this device's refresh token. If absent, revoke all. */
    private String refreshToken;
}
