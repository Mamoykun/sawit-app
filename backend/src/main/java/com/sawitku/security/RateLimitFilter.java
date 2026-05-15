package com.sawitku.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rate-limits endpoints per IP:
 *   - /api/auth/* endpoints: 2 requests per minute
 *   - /api/admin/agent/* endpoints: 60 requests per minute
 *
 * Uses in-memory ConcurrentHashMap of Bucket4j buckets — one bucket per (ip, bucketType) key.
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final int AUTH_MAX_PER_MINUTE = 2;
    private static final int AGENT_MAX_PER_MINUTE = 60;
    private static final long REFILL_SECONDS = 60L;

    private final ConcurrentHashMap<String, Bucket> buckets = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        boolean isAuthPath = path.equals("/api/auth/login")
            || path.equals("/api/auth/register")
            || path.equals("/api/auth/forgot-password")
            || path.equals("/api/auth/reset-password");
        boolean isAgentPath = path.startsWith("/api/admin/agent/");
        return !isAuthPath && !isAgentPath;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String ip = resolveClientIp(request);
        boolean isAgentPath = request.getRequestURI().startsWith("/api/admin/agent/");

        String bucketKey = isAgentPath ? "agent:" + ip : "auth:" + ip;
        int capacity = isAgentPath ? AGENT_MAX_PER_MINUTE : AUTH_MAX_PER_MINUTE;
        Bucket bucket = buckets.computeIfAbsent(bucketKey, k -> newBucket(capacity));

        if (bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
        } else {
            response.setStatus(429);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            Map<String, Object> body = Map.of(
                "error", "Too many requests, try again later",
                "retryAfterSeconds", REFILL_SECONDS
            );
            objectMapper.writeValue(response.getWriter(), body);
        }
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private Bucket newBucket(int capacity) {
        Bandwidth limit = Bandwidth.builder()
            .capacity(capacity)
            .refillGreedy(capacity, Duration.ofSeconds(REFILL_SECONDS))
            .build();
        return Bucket.builder().addLimit(limit).build();
    }
}
