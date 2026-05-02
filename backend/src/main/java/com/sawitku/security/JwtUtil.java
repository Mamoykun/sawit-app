package com.sawitku.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;

@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-expiration}")
    private long accessExpiration;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration;

    private SecretKey getKey() {
        byte[] bytes = Decoders.BASE64.decode(
            java.util.Base64.getEncoder().encodeToString(secret.getBytes())
        );
        return Keys.hmacShaKeyFor(bytes);
    }

    /** Short-lived access token (15 min). Use this for API authorization. */
    public String generateAccessToken(UserDetails user) {
        return Jwts.builder()
            .subject(user.getUsername())
            .claims(Map.of("type", "access"))
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + accessExpiration))
            .signWith(getKey())
            .compact();
    }

    /** Long-lived refresh token (30 days). Stored as hash in DB. */
    public String generateRefreshToken(UserDetails user) {
        return Jwts.builder()
            .subject(user.getUsername())
            .claims(Map.of("type", "refresh"))
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + refreshExpiration))
            .signWith(getKey())
            .compact();
    }

    /** Backward-compat alias — returns an access token. */
    public String generateToken(UserDetails user) {
        return generateAccessToken(user);
    }

    public boolean isRefreshToken(String token) {
        try {
            String type = (String) Jwts.parser().verifyWith(getKey()).build()
                .parseSignedClaims(token).getPayload().get("type");
            return "refresh".equals(type);
        } catch (JwtException e) {
            return false;
        }
    }

    public String extractUsername(String token) {
        return Jwts.parser().verifyWith(getKey()).build()
            .parseSignedClaims(token).getPayload().getSubject();
    }

    public boolean validateToken(String token, UserDetails user) {
        try {
            String username = extractUsername(token);
            return username.equals(user.getUsername()) &&
                   !Jwts.parser().verifyWith(getKey()).build()
                        .parseSignedClaims(token).getPayload().getExpiration().before(new Date());
        } catch (JwtException e) {
            return false;
        }
    }
}
