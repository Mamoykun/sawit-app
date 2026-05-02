package com.sawitku.service;

import com.sawitku.dto.request.*;
import com.sawitku.dto.response.AuthResponse;
import com.sawitku.dto.response.TokenResponse;
import com.sawitku.entity.*;
import com.sawitku.exception.BusinessException;
import com.sawitku.repository.*;
import com.sawitku.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authManager;
    private final EmailService emailService;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpirationMs;

    @Value("${app.email.reset-url-template}")
    private String resetUrlTemplate;

    // ── Register / Login ─────────────────────────────────────────────────────

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

        String accessToken = jwtUtil.generateAccessToken(user);
        String rawRefresh = jwtUtil.generateRefreshToken(user);
        persistRefreshToken(user, rawRefresh, null, null);
        return buildAuthResponse(accessToken, rawRefresh, user, sub);
    }

    @Transactional
    public AuthResponse login(LoginRequest req, String userAgent, String ipAddress) {
        authManager.authenticate(new UsernamePasswordAuthenticationToken(req.getEmail(), req.getPassword()));
        User user = userRepository.findByEmail(req.getEmail()).orElseThrow();
        Subscription sub = subscriptionRepository.findByUserId(user.getId()).orElseThrow();
        String accessToken = jwtUtil.generateAccessToken(user);
        String rawRefresh = jwtUtil.generateRefreshToken(user);
        persistRefreshToken(user, rawRefresh, userAgent, ipAddress);
        return buildAuthResponse(accessToken, rawRefresh, user, sub);
    }

    // ── Refresh Token ─────────────────────────────────────────────────────────

    /**
     * Rotate refresh token: validate the incoming token, revoke it, issue a new pair.
     */
    @Transactional
    public TokenResponse refresh(String rawRefreshToken) {
        // 1. Structurally valid JWT of type "refresh"?
        if (!jwtUtil.isRefreshToken(rawRefreshToken)) {
            throw new BusinessException("Refresh token tidak valid", "INVALID_REFRESH_TOKEN");
        }

        try {
            jwtUtil.extractUsername(rawRefreshToken);
        } catch (Exception e) {
            throw new BusinessException("Refresh token tidak valid", "INVALID_REFRESH_TOKEN");
        }

        // 2. Exists in DB and not revoked / not expired?
        String hash = sha256Hex(rawRefreshToken);
        RefreshToken stored = refreshTokenRepository.findByTokenHash(hash)
            .orElseThrow(() -> new BusinessException("Refresh token tidak ditemukan", "INVALID_REFRESH_TOKEN"));

        if (stored.isRevoked()) {
            throw new BusinessException("Refresh token sudah dicabut", "REFRESH_TOKEN_REVOKED");
        }
        if (stored.isExpired()) {
            throw new BusinessException("Refresh token sudah expired", "REFRESH_TOKEN_EXPIRED");
        }

        // 3. Revoke old token (rotation)
        stored.setRevokedAt(Instant.now());
        refreshTokenRepository.save(stored);

        // 4. Issue new pair
        User user = stored.getUser();
        String newAccess = jwtUtil.generateAccessToken(user);
        String newRawRefresh = jwtUtil.generateRefreshToken(user);
        persistRefreshToken(user, newRawRefresh,
            stored.getUserAgent(), stored.getIpAddress());

        return new TokenResponse(newAccess, newRawRefresh);
    }

    /**
     * Logout: revoke one refresh token (current device) or all (all devices).
     */
    @Transactional
    public void logout(User user, String rawRefreshToken) {
        if (rawRefreshToken != null && !rawRefreshToken.isBlank()) {
            String hash = sha256Hex(rawRefreshToken);
            refreshTokenRepository.findByTokenHash(hash).ifPresent(rt -> {
                rt.setRevokedAt(Instant.now());
                refreshTokenRepository.save(rt);
            });
        } else {
            refreshTokenRepository.deleteByUserId(user.getId());
        }
    }

    // ── Password Reset ────────────────────────────────────────────────────────

    /**
     * Initiate password reset. Always returns normally — does not reveal
     * whether the email is registered (prevents user enumeration).
     */
    @Transactional
    public void forgotPassword(String email) {
        userRepository.findByEmail(email).ifPresent(user -> {
            // Generate 64-byte random token, URL-safe base64 encoded
            byte[] bytes = new byte[48]; // 48 bytes → 64 base64 chars
            SECURE_RANDOM.nextBytes(bytes);
            String plainToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

            String tokenHash = sha256Hex(plainToken);
            PasswordResetToken prt = PasswordResetToken.builder()
                .user(user)
                .tokenHash(tokenHash)
                .expiresAt(Instant.now().plusSeconds(3600)) // 1 hour
                .createdAt(Instant.now())
                .build();
            passwordResetTokenRepository.save(prt);

            String resetUrl = resetUrlTemplate.replace("{token}", plainToken);
            try {
                emailService.sendPasswordReset(user.getEmail(), user.getName(), resetUrl);
            } catch (Exception e) {
                log.error("Failed to send password reset email to {}: {}", email, e.getMessage());
                // Don't rethrow — we don't want to reveal email existence via error
            }
        });
    }

    /**
     * Complete password reset using the plaintext token from the email link.
     */
    @Transactional
    public void resetPassword(String plainToken, String newPassword) {
        String tokenHash = sha256Hex(plainToken);
        PasswordResetToken prt = passwordResetTokenRepository.findByTokenHash(tokenHash)
            .orElseThrow(() -> new BusinessException("Token tidak valid atau sudah digunakan", "INVALID_RESET_TOKEN"));

        if (prt.isUsed()) {
            throw new BusinessException("Token sudah digunakan", "RESET_TOKEN_USED");
        }
        if (prt.isExpired()) {
            throw new BusinessException("Token sudah expired", "RESET_TOKEN_EXPIRED");
        }

        User user = prt.getUser();
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Mark token as used
        prt.setUsedAt(Instant.now());
        passwordResetTokenRepository.save(prt);

        // Force re-login on all devices
        refreshTokenRepository.deleteByUserId(user.getId());
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void persistRefreshToken(User user, String rawToken,
                                     String userAgent, String ipAddress) {
        RefreshToken rt = RefreshToken.builder()
            .user(user)
            .tokenHash(sha256Hex(rawToken))
            .expiresAt(Instant.now().plusMillis(refreshExpirationMs))
            .createdAt(Instant.now())
            .userAgent(userAgent)
            .ipAddress(ipAddress)
            .build();
        refreshTokenRepository.save(rt);
    }

    private AuthResponse buildAuthResponse(String token, String refreshToken,
                                           User user, Subscription sub) {
        return AuthResponse.builder()
            .token(token)
            .refreshToken(refreshToken)
            .user(AuthResponse.UserInfo.builder()
                .id(user.getId()).name(user.getName())
                .email(user.getEmail()).phone(user.getPhone()).build())
            .subscription(AuthResponse.SubscriptionInfo.builder()
                .paket(sub.getPaket().name()).status(sub.getStatus())
                .expiredAt(sub.getExpiredAt() != null ? sub.getExpiredAt().toString() : null).build())
            .build();
    }

    public static String sha256Hex(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(bytes);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
