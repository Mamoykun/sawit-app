package com.sawitku.service;

import com.sawitku.dto.request.*;
import com.sawitku.dto.response.AuthResponse;
import com.sawitku.entity.*;
import com.sawitku.exception.BusinessException;
import com.sawitku.repository.*;
import com.sawitku.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authManager;

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        if (userRepository.existsByEmail(req.getEmail()))
            throw new BusinessException("Email sudah digunakan", "EMAIL_EXISTS");

        User user = User.builder()
            .name(req.getName()).email(req.getEmail())
            .password(passwordEncoder.encode(req.getPassword()))
            .phone(req.getPhone()).build();
        userRepository.save(user);

        Subscription sub = Subscription.builder()
            .user(user).paket(PaketSubscription.GRATIS)
            .status("ACTIVE").createdAt(LocalDateTime.now()).build();
        subscriptionRepository.save(sub);

        String token = jwtUtil.generateToken(user);
        return buildAuthResponse(token, user, sub);
    }

    public AuthResponse login(LoginRequest req) {
        authManager.authenticate(new UsernamePasswordAuthenticationToken(req.getEmail(), req.getPassword()));
        User user = userRepository.findByEmail(req.getEmail()).orElseThrow();
        Subscription sub = subscriptionRepository.findByUserId(user.getId()).orElseThrow();
        return buildAuthResponse(jwtUtil.generateToken(user), user, sub);
    }

    private AuthResponse buildAuthResponse(String token, User user, Subscription sub) {
        return AuthResponse.builder()
            .token(token)
            .user(AuthResponse.UserInfo.builder()
                .id(user.getId()).name(user.getName())
                .email(user.getEmail()).phone(user.getPhone()).build())
            .subscription(AuthResponse.SubscriptionInfo.builder()
                .paket(sub.getPaket().name()).status(sub.getStatus())
                .expiredAt(sub.getExpiredAt() != null ? sub.getExpiredAt().toString() : null).build())
            .build();
    }
}
