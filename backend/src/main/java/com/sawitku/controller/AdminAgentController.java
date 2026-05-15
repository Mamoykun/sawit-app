package com.sawitku.controller;

import com.sawitku.entity.PaymentStatus;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.*;
import com.sawitku.service.AiTelemetryService;
import com.sawitku.service.AiUsageService;
import com.sawitku.service.AuditService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.jdbc.core.JdbcTemplate;
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
    private final AiUsageService aiUsageService;
    private final UserRepository userRepo;
    private final AuditLogRepository auditRepo;
    private final PanenRepository panenRepo;
    private final BiayaRepository biayaRepo;
    private final LahanRepository lahanRepo;
    private final PaymentRepository paymentRepo;
    private final AuditService auditService;
    private final JdbcTemplate jdbcTemplate;

    /**
     * Daily/weekly/monthly summary metrics.
     * GET /api/admin/agent/summary?period=today|week|month
     */
    @GetMapping("/summary")
    public Map<String, Object> summary(@RequestParam(defaultValue = "today") String period) {
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "summary", "period", period));
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
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "alerts/active"));
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
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "audit/recent", "limit", limit));
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
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "users/stats"));
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
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "chat-context"));
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
     * Payment summary: revenue, recent transactions, breakdown by status.
     * GET /api/admin/agent/payments?limit=20
     */
    @GetMapping("/payments")
    public Map<String, Object> payments(@RequestParam(defaultValue = "20") int limit) {
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "payments"));
        int capped = Math.min(limit, 100);
        Map<String, Object> result = new LinkedHashMap<>();
        try {
            result.put("totalRevenue", paymentRepo.sumGrossAmountByStatus(PaymentStatus.PAID));
            result.put("countByStatus", Map.of(
                "PAID",    safeCount(() -> paymentRepo.countByStatus(PaymentStatus.PAID), "countPaid"),
                "PENDING", safeCount(() -> paymentRepo.countByStatus(PaymentStatus.PENDING), "countPending"),
                "FAILED",  safeCount(() -> paymentRepo.countByStatus(PaymentStatus.FAILED), "countFailed"),
                "EXPIRED", safeCount(() -> paymentRepo.countByStatus(PaymentStatus.EXPIRED), "countExpired")
            ));
            var recent = paymentRepo.findAllByOrderByCreatedAtDesc(PageRequest.of(0, capped))
                    .stream().map(p -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("id", p.getId());
                        m.put("orderId", p.getOrderId());
                        m.put("userEmail", p.getUser() != null ? p.getUser().getEmail() : null);
                        m.put("targetPaket", p.getTargetPaket());
                        m.put("grossAmount", p.getGrossAmount());
                        m.put("status", p.getStatus());
                        m.put("paymentMethod", p.getPaymentMethod());
                        m.put("createdAt", p.getCreatedAt() != null ? p.getCreatedAt().toString() : null);
                        m.put("paidAt", p.getPaidAt() != null ? p.getPaidAt().toString() : null);
                        return m;
                    }).toList();
            result.put("recent", recent);
        } catch (Exception e) {
            log.warn("adminAgent: payments query failed: {}", e.getMessage());
            result.put("error", "unavailable");
        }
        return result;
    }

    /**
     * Filtered audit log query with pagination.
     * GET /api/admin/agent/audit?action=AUTH_LOGIN_FAILED&from=2025-01-01T00:00:00Z&to=2025-12-31T23:59:59Z&success=false&limit=100&offset=0
     */
    @GetMapping("/audit")
    public Map<String, Object> auditFiltered(
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(required = false) Boolean success,
            @RequestParam(defaultValue = "100") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "audit", "action", action != null ? action : "",
                       "limit", limit, "offset", offset));
        int capped = Math.min(limit, 500);
        Instant fromInstant = from != null ? Instant.parse(from) : null;
        Instant toInstant   = to   != null ? Instant.parse(to)   : null;
        try {
            var page = auditRepo.findFiltered(action, fromInstant, toInstant, success,
                    PageRequest.of(offset / Math.max(capped, 1), capped));
            var logs = page.getContent().stream().map(a -> {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("occurredAt", a.getOccurredAt().toString());
                m.put("action", a.getAction());
                m.put("userId", a.getUserId());
                m.put("userEmail", a.getUserEmail() != null ? a.getUserEmail() : "");
                m.put("entityType", a.getEntityType());
                m.put("entityId", a.getEntityId());
                m.put("ipAddress", a.getIpAddress());
                m.put("success", Boolean.TRUE.equals(a.getSuccess()));
                return m;
            }).toList();
            return Map.of("logs", logs, "total", page.getTotalElements(),
                          "limit", capped, "offset", offset);
        } catch (Exception e) {
            log.warn("adminAgent: audit filtered query failed: {}", e.getMessage());
            return Map.of("logs", List.of(), "error", "unavailable");
        }
    }

    /**
     * Per-user detail: profile, AI usage, audit history.
     * GET /api/admin/agent/users/{id}
     */
    @GetMapping("/users/{id}")
    public Map<String, Object> userDetail(@PathVariable Long id) {
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "users/detail", "targetUserId", id));
        Map<String, Object> result = new LinkedHashMap<>();
        try {
            var userOpt = userRepo.findById(id);
            if (userOpt.isEmpty()) return Map.of("error", "User not found");
            var u = userOpt.get();
            result.put("id", u.getId());
            result.put("name", u.getName());
            result.put("email", u.getEmail());
            result.put("createdAt", u.getCreatedAt() != null ? u.getCreatedAt().toString() : null);
        } catch (Exception e) {
            log.warn("adminAgent: user profile query failed for {}: {}", id, e.getMessage());
        }
        try {
            var stats = aiUsageService.getStats(id);
            result.put("aiUsage", Map.of(
                "callCount", stats.callCount(),
                "costCents", stats.costCents(),
                "capCents", stats.capCents(),
                "percentUsed", stats.percentUsed()
            ));
        } catch (Exception e) {
            log.warn("adminAgent: ai usage query failed for {}: {}", id, e.getMessage());
            result.put("aiUsage", Map.of("error", "unavailable"));
        }
        try {
            result.put("lahanCount", safeCount(() -> lahanRepo.countByUserIdAndIsActiveTrue(id), "lahanCount"));
            result.put("panenCount", safeCount(() -> panenRepo.countByUserId(id), "panenCount"));
        } catch (Exception e) {
            log.warn("adminAgent: entity counts failed for {}: {}", id, e.getMessage());
        }
        try {
            var auditLogs = auditRepo.findByUserIdOrderByOccurredAtDesc(id, PageRequest.of(0, 20))
                    .getContent().stream().map(a -> {
                        Map<String, Object> m = new LinkedHashMap<>();
                        m.put("occurredAt", a.getOccurredAt().toString());
                        m.put("action", a.getAction());
                        m.put("entityType", a.getEntityType());
                        m.put("success", Boolean.TRUE.equals(a.getSuccess()));
                        return m;
                    }).toList();
            result.put("recentAudit", auditLogs);
        } catch (Exception e) {
            log.warn("adminAgent: user audit query failed for {}: {}", id, e.getMessage());
            result.put("recentAudit", List.of());
        }
        return result;
    }

    /**
     * System health: DB connectivity, Redis ping, uptime.
     * GET /api/admin/agent/system/health
     */
    @GetMapping("/system/health")
    public Map<String, Object> systemHealth() {
        auditService.log(AuditAction.ADMIN_AGENT_API_CALL, null, "AdminAgent", null,
                Map.of("endpoint", "system/health"));
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("checkedAt", Instant.now().toString());

        // DB health
        boolean dbOk = false;
        try {
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            dbOk = true;
        } catch (Exception e) {
            log.warn("adminAgent: DB health check failed: {}", e.getMessage());
        }
        result.put("database", Map.of("status", dbOk ? "ok" : "error"));

        // Aggregate health
        result.put("status", dbOk ? "ok" : "degraded");
        return result;
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
