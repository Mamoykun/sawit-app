package com.sawitku.controller;

import com.sawitku.entity.PaketSubscription;
import com.sawitku.entity.PaymentStatus;
import com.sawitku.repository.*;
import com.sawitku.service.AiTelemetryService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.*;

/**
 * Server-rendered admin dashboard. All pages are read-only (Phase 1).
 * Auth: session-based form login via AdminSecurityConfig, gated by ADMIN_EMAILS allowlist.
 */
@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminWebController {

    private final AiTelemetryService telemetryService;
    private final UserRepository userRepo;
    private final AuditLogRepository auditRepo;
    private final PanenRepository panenRepo;
    private final SubscriptionRepository subscriptionRepo;
    private final PaymentRepository paymentRepo;
    private final AiUsageRepository aiUsageRepo;

    @Value("${app.admin-emails:}")
    private String adminEmailsCsv;

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private boolean isAdmin(Authentication auth) {
        if (auth == null || auth.getName() == null) return false;
        String email = auth.getName().toLowerCase();
        return Arrays.stream(adminEmailsCsv.split(","))
            .map(String::trim).map(String::toLowerCase)
            .anyMatch(e -> !e.isEmpty() && e.equals(email));
    }

    private void common(Model model, Authentication auth, String path) {
        model.addAttribute("adminEmail", auth != null ? auth.getName() : "");
        model.addAttribute("currentPath", path);
        model.addAttribute("navItems", List.of(
            nav("/admin/",            "Overview"),
            nav("/admin/users",       "Users"),
            nav("/admin/ai-cost",     "AI Cost"),
            nav("/admin/sync-health", "Sync Health"),
            nav("/admin/audit",       "Audit Log"),
            nav("/admin/payments",    "Payments"),
            nav("/admin/agent-config","Admin Agent")
        ));
    }

    private Map<String, String> nav(String path, String label) {
        return Map.of("path", path, "label", label);
    }

    private String denyIfNotAdmin(Authentication auth) {
        return isAdmin(auth) ? null : "redirect:/admin/forbidden";
    }

    // ─── Login ────────────────────────────────────────────────────────────────

    @GetMapping("/login")
    public String loginPage(@RequestParam(required = false) String error,
                            @RequestParam(required = false) String logout,
                            Model model) {
        model.addAttribute("loginError", error != null);
        model.addAttribute("logoutMsg", logout != null);
        return "admin/login";
    }

    // ─── Overview ─────────────────────────────────────────────────────────────

    @GetMapping({"/", ""})
    public String overview(Model model, Authentication auth) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/");

        model.addAttribute("totalUsers", userRepo.count());
        model.addAttribute("activeToday", auditRepo.countDistinctUsersToday());
        model.addAttribute("gratisCount", subscriptionRepo.countByPaket(PaketSubscription.GRATIS));
        model.addAttribute("petaniCount", subscriptionRepo.countByPaket(PaketSubscription.PETANI));
        model.addAttribute("proCount",    subscriptionRepo.countByPaket(PaketSubscription.PRO));

        var telemetry = telemetryService.getCurrentTelemetry();
        model.addAttribute("aiCostCents", telemetry.getTotalCostCents());
        model.addAttribute("aiPeriod",    telemetry.getPeriod());

        var recentLogs = auditRepo.findAllByOrderByOccurredAtDesc(PageRequest.of(0, 5));
        model.addAttribute("recentLogs", recentLogs.getContent());

        return "admin/overview";
    }

    // ─── Users ────────────────────────────────────────────────────────────────

    @GetMapping("/users")
    public String users(Model model, Authentication auth,
                        @RequestParam(required = false) String search,
                        @RequestParam(defaultValue = "0") int page) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/users");

        var allUsers = userRepo.findAll(PageRequest.of(page, 50));
        var filtered = allUsers.getContent().stream()
            .filter(u -> search == null || search.isBlank()
                || u.getEmail().toLowerCase().contains(search.toLowerCase())
                || u.getName().toLowerCase().contains(search.toLowerCase()))
            .toList();

        model.addAttribute("users", filtered);
        model.addAttribute("search", search);
        model.addAttribute("page", page);
        model.addAttribute("hasMore", allUsers.hasNext());
        return "admin/users";
    }

    @GetMapping("/users/{id}")
    public String userDetail(@PathVariable Long id, Model model, Authentication auth) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/users");

        var user = userRepo.findById(id).orElseThrow();
        model.addAttribute("user", user);

        String period = currentPeriod();
        model.addAttribute("aiCostCents", aiUsageRepo.sumCostByUserPeriod(id, period));
        model.addAttribute("aiCalls", aiUsageRepo.countByUserIdAndPeriod(id, period));
        model.addAttribute("aiPeriod", period);
        model.addAttribute("panenCount", panenRepo.countByUserId(id));
        model.addAttribute("lahanCount", user.getLahans() != null ? user.getLahans().size() : 0);

        var auditPage = auditRepo.findByUserIdOrderByOccurredAtDesc(id, PageRequest.of(0, 20));
        model.addAttribute("auditLogs", auditPage.getContent());

        return "admin/user-detail";
    }

    // ─── AI Cost ──────────────────────────────────────────────────────────────

    @GetMapping("/ai-cost")
    public String aiCost(Model model, Authentication auth) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/ai-cost");

        var telemetry = telemetryService.getCurrentTelemetry();
        model.addAttribute("telemetry", telemetry);
        return "admin/ai-cost";
    }

    // ─── Sync Health ──────────────────────────────────────────────────────────

    @GetMapping("/sync-health")
    public String syncHealth(Model model, Authentication auth) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/sync-health");

        model.addAttribute("totalUsers", userRepo.count());
        model.addAttribute("activeToday", auditRepo.countDistinctUsersToday());
        return "admin/sync-health";
    }

    // ─── Audit Log ────────────────────────────────────────────────────────────

    @GetMapping("/audit")
    public String audit(Model model, Authentication auth,
                        @RequestParam(required = false) String action,
                        @RequestParam(defaultValue = "0") int page) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/audit");

        var pageable = PageRequest.of(page, 100);
        var logs = (action != null && !action.isBlank())
            ? auditRepo.findByActionOrderByOccurredAtDesc(action, pageable)
            : auditRepo.findAllByOrderByOccurredAtDesc(pageable);

        model.addAttribute("logs", logs.getContent());
        model.addAttribute("filterAction", action);
        model.addAttribute("page", page);
        model.addAttribute("hasMore", logs.hasNext());
        model.addAttribute("actionOptions", List.of(
            "AUTH_LOGIN_SUCCESS", "AUTH_LOGIN_FAIL", "AUTH_REGISTER",
            "PANEN_CREATE", "PANEN_UPDATE", "PANEN_DELETE",
            "LAHAN_CREATE", "LAHAN_UPDATE", "LAHAN_DELETE",
            "DIAGNOSA_CREATE", "AI_USAGE", "PAYMENT_SUCCESS"
        ));
        return "admin/audit";
    }

    // ─── Payments ─────────────────────────────────────────────────────────────

    @GetMapping("/payments")
    public String payments(Model model, Authentication auth) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/payments");

        var paketBreakdown = subscriptionRepo.countActiveByPaket();
        model.addAttribute("paketBreakdown", paketBreakdown);

        var recentPayments = paymentRepo.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 20));
        model.addAttribute("recentPayments", recentPayments);

        BigDecimal totalRevenue = paymentRepo.sumGrossAmountByStatus(PaymentStatus.PAID);
        model.addAttribute("totalRevenue", totalRevenue != null ? totalRevenue : BigDecimal.ZERO);

        return "admin/payments";
    }

    // ─── Agent Config ─────────────────────────────────────────────────────────

    @GetMapping("/agent-config")
    public String agentConfig(Model model, Authentication auth) {
        String deny = denyIfNotAdmin(auth);
        if (deny != null) return deny;
        common(model, auth, "/admin/agent-config");
        return "admin/agent-config";
    }

    // ─── Forbidden ────────────────────────────────────────────────────────────

    @GetMapping("/forbidden")
    public String forbidden(Model model) {
        return "admin/forbidden";
    }

    // ─── Util ─────────────────────────────────────────────────────────────────

    private String currentPeriod() {
        return java.time.LocalDate.now(java.time.ZoneId.of("Asia/Jakarta"))
            .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM"));
    }
}
