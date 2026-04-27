package com.sawitku.controller;

import com.sawitku.dto.request.*;
import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.repository.SubscriptionRepository;
import com.sawitku.service.AuthService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final SubscriptionRepository subscriptionRepository;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest req) {
        return ResponseUtil.ok(authService.register(req), "Registrasi berhasil");
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest req) {
        return ResponseUtil.ok(authService.login(req), "Login berhasil");
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse.UserInfo>> me(@AuthenticationPrincipal User user) {
        return ResponseUtil.ok(AuthResponse.UserInfo.builder()
            .id(user.getId()).name(user.getName())
            .email(user.getEmail()).phone(user.getPhone()).build());
    }
}
