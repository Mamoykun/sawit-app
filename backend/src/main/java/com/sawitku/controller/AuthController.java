package com.sawitku.controller;

import com.sawitku.dto.request.*;
import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.repository.SubscriptionRepository;
import com.sawitku.service.AuthService;
import com.sawitku.util.ResponseUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final SubscriptionRepository subscriptionRepository;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest req,
            HttpServletRequest httpReq) {
        return ResponseUtil.ok(authService.register(req), "Registrasi berhasil");
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest req,
            HttpServletRequest httpReq) {
        String userAgent = httpReq.getHeader("User-Agent");
        String ip = resolveIp(httpReq);
        return ResponseUtil.ok(authService.login(req, userAgent, ip), "Login berhasil");
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<TokenResponse>> refresh(
            @Valid @RequestBody RefreshTokenRequest req) {
        TokenResponse tokens = authService.refresh(req.getRefreshToken());
        return ResponseUtil.ok(tokens, "Token diperbarui");
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @AuthenticationPrincipal User user,
            @RequestBody(required = false) LogoutRequest req) {
        String rawRefresh = (req != null) ? req.getRefreshToken() : null;
        authService.logout(user, rawRefresh);
        return ResponseUtil.ok(null, "Logout berhasil");
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<Map<String, String>>> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest req,
            HttpServletRequest httpReq) {
        authService.forgotPassword(req.getEmail());
        return ResponseUtil.ok(
            Map.of("message", "Jika email terdaftar, link reset sudah dikirim."),
            "Permintaan diterima"
        );
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Map<String, String>>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest req) {
        authService.resetPassword(req.getToken(), req.getNewPassword());
        return ResponseUtil.ok(
            Map.of("message", "Password berhasil diubah."),
            "Password berhasil diubah"
        );
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse.UserInfo>> me(@AuthenticationPrincipal User user) {
        return ResponseUtil.ok(AuthResponse.UserInfo.builder()
            .id(user.getId()).name(user.getName())
            .email(user.getEmail()).phone(user.getPhone()).build());
    }

    private String resolveIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
