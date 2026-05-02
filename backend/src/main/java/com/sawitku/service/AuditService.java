package com.sawitku.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.entity.AuditLog;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.Instant;
import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;
    private final ObjectMapper objectMapper;

    /**
     * Log a business-entity action (lahan, panen, biaya, diagnosa, payment, profile).
     * Pulls IP + User-Agent from the current request context if available.
     */
    @Async
    public void log(AuditAction action, Long userId, String entityType, Long entityId,
                    Map<String, Object> metadata) {
        try {
            AuditLog entry = AuditLog.builder()
                .occurredAt(Instant.now())
                .userId(userId)
                .action(action.name())
                .entityType(entityType)
                .entityId(entityId)
                .ipAddress(extractIp())
                .userAgent(extractUserAgent())
                .metadata(serializeMetadata(metadata))
                .success(true)
                .build();
            auditLogRepository.save(entry);
        } catch (Exception e) {
            log.error("Audit log write failed for action {}: {}", action, e.getMessage());
        }
    }

    /**
     * Log an auth event. userId may be null for failed logins where user was not found.
     */
    @Async
    public void logAuth(AuditAction action, String email, boolean success,
                        Map<String, Object> metadata) {
        try {
            AuditLog entry = AuditLog.builder()
                .occurredAt(Instant.now())
                .userEmail(email)
                .action(action.name())
                .ipAddress(extractIp())
                .userAgent(extractUserAgent())
                .metadata(serializeMetadata(metadata))
                .success(success)
                .build();
            auditLogRepository.save(entry);
        } catch (Exception e) {
            log.error("Audit log write failed for auth action {}: {}", action, e.getMessage());
        }
    }

    /**
     * Log an auth event with a known userId (e.g. after successful lookup).
     */
    @Async
    public void logAuthWithUserId(AuditAction action, Long userId, String email, boolean success,
                                  Map<String, Object> metadata) {
        try {
            AuditLog entry = AuditLog.builder()
                .occurredAt(Instant.now())
                .userId(userId)
                .userEmail(email)
                .action(action.name())
                .ipAddress(extractIp())
                .userAgent(extractUserAgent())
                .metadata(serializeMetadata(metadata))
                .success(success)
                .build();
            auditLogRepository.save(entry);
        } catch (Exception e) {
            log.error("Audit log write failed for auth action {}: {}", action, e.getMessage());
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private String extractIp() {
        try {
            ServletRequestAttributes attrs =
                (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
            String forwarded = attrs.getRequest().getHeader("X-Forwarded-For");
            if (forwarded != null && !forwarded.isBlank()) {
                return forwarded.split(",")[0].trim();
            }
            return attrs.getRequest().getRemoteAddr();
        } catch (Exception ignored) {
            return null;
        }
    }

    private String extractUserAgent() {
        try {
            ServletRequestAttributes attrs =
                (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
            String ua = attrs.getRequest().getHeader("User-Agent");
            if (ua != null && ua.length() > 500) {
                return ua.substring(0, 500);
            }
            return ua;
        } catch (Exception ignored) {
            return null;
        }
    }

    private String serializeMetadata(Map<String, Object> metadata) {
        if (metadata == null || metadata.isEmpty()) return null;
        try {
            return objectMapper.writeValueAsString(metadata);
        } catch (Exception e) {
            log.warn("Failed to serialize audit metadata: {}", e.getMessage());
            return null;
        }
    }
}
