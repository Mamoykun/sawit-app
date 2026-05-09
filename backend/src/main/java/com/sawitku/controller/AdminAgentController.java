package com.sawitku.controller;

import com.sawitku.repository.*;
import com.sawitku.service.AiTelemetryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.*;
import java.util.*;

/**
 * Read-only API for OpenClaw external agent (runs on VPS).
 * Auth: X-Admin-Agent-Key header validated by AdminAgentKeyFilter.
 * Rate limit: 60 req/min per IP via RateLimitFilter.
 * All stat queries are wrapped in try/catch — partial data preferred over 500.
 */
@RestController
@RequestMapping("/api/admin/agent")
@RequiredArgsConstructor
@Slf4j
public class AdminAgentController {

    private final AiTelemetryService telemetryService;
    private final UserRepository userRepo;
    private final AuditLogRepository auditRepo;
    private final PanenRepository panenRepo;
    private final BiayaRepository biayaRepo;
    private final LahanRepository lahanRepo;

    /**
     * Daily/weekly/monthly summary metrics.
     * GET /api/admin/agent/summary?period=today|week|month
     */
    @GetMapping("/summary")
    public Map<String, Object> summary(@RequestParam(defaultValue = "today") String period) {
        ZoneId jakarta = ZoneId.of("Asia/Jakarta");
        ZonedDateTime now = ZonedDateTime.now(jakarta);
        Instant since = switch (period) {
            case "week"  -> now.minusWeeks(1).toInstant();
            case "month" -> now.minusMonths(1).toInstant();
            default      -> now.toLocalDate().atStartOfDay(jakarta).toInstant();
        };
        LocalDateTime sinceLocal = LocalDateTime.ofInstant(since, jakarta);

        long totalUsers  = safeCount(() -> userRepo.count(), "userRepo.count");
        long activeUsers = safeCount(() -> auditRepo.countDistinctUsersSince(since), "auditRepo.countDistinctUsersSince");
        long panenCount  = safeCount(() -> panenRepo.countByCreatedAtAfter(sinceLocal), "panenRepo.countByCreatedAtAfter");
        long biayaCount  = safeCount(() -> biayaRepo.countByCreatedAtAfter(sinceLocal), "biayaRepo.countByCreatedAtAfter");
        long lahanCount  = safeCount(() -> lahanRepo.count(), "lahanRepo.count");

        Map<String, Object> aiData = new LinkedHashMap<>();
        try {
            var telemetry = telemetryService.getCurrentTelemetry();
            aiData.put("totalCostCents", telemetry.getTotalCostCents());
            aiData.put("activeUsers", telemetry.getActiveUsers());
            aiData.put("modelBreakdown", telemetry.getModelBreakdown());
            aiData.put("topSpenders", telemetry.getTopSpenders());
        } catch (Exception e) {
            log.warn("adminAgent: telemetry query failed: {}", e.getMessage());
            aiData.put("error", "unavailable");
        }

        return Map.of(
            "period", period,
            "since", since.toString(),
            "users", Map.of("total", totalUsers, "active", activeUsers),
            "panen", Map.of("count", panenCount),
            "biaya", Map.of("count", biayaCount),
            "lahan", Map.of("count", lahanCount),
            "ai", aiData
        );
    }

    /**
     * Active alerts that need attention.
     * GET /api/admin/agent/alerts/active
     */
    @GetMapping("/alerts/active")
    public Map<String, Object> activeAlerts() {
        List<Map<String, Object>> alerts = new ArrayList<>();

        // Alert: AI cost high (> $10 this month)
        try {
            var telemetry = telemetryService.getCurrentTelemetry();
            if (telemetry.getTotalCostCents() > 1000) {
                alerts.add(Map.of(
                    "severity", "warning",
                    "type", "ai_cost_high",
                    "message", "AI cost bulan ini sudah $" + String.format("%.2f", telemetry.getTotalCostCents() / 100.0),
                    "value", telemetry.getTotalCostCents()
                ));
            }
        } catch (Exception e) {
            log.warn("adminAgent: ai cost alert check failed: {}", e.getMessage());
        }

        // Alert: No new panen in last 7 days
        try {
            LocalDateTime weekAgo = LocalDateTime.now(ZoneId.of("Asia/Jakarta")).minusDays(7);
            long recentPanen = panenRepo.countByCreatedAtAfter(weekAgo);
            if (recentPanen == 0) {
                alerts.add(Map.of(
                    "severity", "info",
                    "type", "low_activity",
                    "message", "Tidak ada panen baru dalam 7 hari terakhir",
                    "value", 0
                ));
            }
        } catch (Exception e) {
            log.warn("adminAgent: panen activity alert check failed: {}", e.getMessage());
        }

        // Alert: Failed login spike (> 20 in last 15 min)
        try {
            Instant fifteenMinAgo = Instant.now().minus(Duration.ofMinutes(15));
            long failedLogins = auditRepo.countByActionAndOccurredAtAfter("AUTH_LOGIN_FAILED", fifteenMinAgo);
            if (failedLogins > 20) {
                alerts.add(Map.of(
                    "severity", "critical",
                    "type", "failed_login_spike",
                    "message", failedLogins + " failed login attempts in last 15 minutes",
                    "value", failedLogins
                ));
            }
        } catch (Exception e) {
            log.warn("adminAgent: failed login alert check failed: {}", e.getMessage());
        }

        return Map.of("alerts", alerts, "checkedAt", Instant.now().toString());
    }

    /**
     * Recent audit events for chat context / activity feed.
     * GET /api/admin/agent/audit/recent?limit=50
     */
    @GetMapping("/audit/recent")
    public Map<String, Object> auditRecent(@RequestParam(defaultValue = "50") int limit) {
        int capped = Math.min(limit, 200);
        try {
            var logs = auditRepo.findTop50ByOrderByOccurredAtDesc();
            var mapped = logs.stream().limit(capped).map(a -> {
                Map<String, Object> entry = new LinkedHashMap<>();
                entry.put("occurredAt", a.getOccurredAt().toString());
                entry.put("action", a.getAction());
                entry.put("userEmail", a.getUserEmail() != null ? a.getUserEmail() : "");
                entry.put("success", Boolean.TRUE.equals(a.getSuccess()));
                return entry;
            }).toList();
            return Map.of("logs", mapped);
        } catch (Exception e) {
            log.warn("adminAgent: audit recent query failed: {}", e.getMessage());
            return Map.of("logs", List.of(), "error", "unavailable");
        }
    }

    /**
     * User activity counts.
     * GET /api/admin/agent/users/stats
     */
    @GetMapping("/users/stats")
    public Map<String, Object> usersStats() {
        ZoneId jakarta = ZoneId.of("Asia/Jakarta");
        LocalDateTime dayAgo  = LocalDateTime.now(jakarta).minusDays(1);
        LocalDateTime weekAgo = LocalDateTime.now(jakarta).minusDays(7);
        Instant dayAgoInstant  = dayAgo.atZone(jakarta).toInstant();
        Instant weekAgoInstant = weekAgo.atZone(jakarta).toInstant();

        long total        = safeCount(() -> userRepo.count(), "userRepo.count");
        long activeDay    = safeCount(() -> auditRepo.countDistinctUsersSince(dayAgoInstant), "activeDay");
        long activeWeek   = safeCount(() -> auditRepo.countDistinctUsersSince(weekAgoInstant), "activeWeek");
        long newUsersToday = safeCount(() -> userRepo.countByCreatedAtAfter(dayAgo), "newUsersToday");

        return Map.of(
            "total", total,
            "activeToday", activeDay,
            "activeWeek", activeWeek,
            "newUsersToday", newUsersToday
        );
    }

    /**
     * Compact context blob for chat queries — combines all endpoints above.
     * GET /api/admin/agent/chat-context
     */
    @GetMapping("/chat-context")
    public Map<String, Object> chatContext() {
        var summary   = summary("today");
        var alertsMap = activeAlerts();
        var users     = usersStats();
        var auditMap  = auditRecent(20);
        return Map.of(
            "today", summary,
            "alerts", alertsMap.get("alerts"),
            "users", users,
            "recentEvents", auditMap.get("logs")
        );
    }

    /**
     * Health check — agent uses this to verify connectivity.
     * GET /api/admin/agent/health
     */
    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
            "status", "ok",
            "timestamp", Instant.now().toString()
        );
    }

    // ---- helpers ----

    private long safeCount(CountSupplier supplier, String label) {
        try {
            return supplier.get();
        } catch (Exception e) {
            log.warn("adminAgent: {} failed: {}", label, e.getMessage());
            return -1L;
        }
    }

    @FunctionalInterface
    private interface CountSupplier {
        long get() throws Exception;
    }
}
