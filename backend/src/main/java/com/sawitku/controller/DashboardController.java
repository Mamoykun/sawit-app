package com.sawitku.controller;

import com.sawitku.dto.response.ApiResponse;
import com.sawitku.dto.response.PortfolioResponse;
import com.sawitku.dto.response.ProfitLossResponse;
import com.sawitku.entity.User;
import com.sawitku.service.ProfitLossService;
import com.sawitku.util.ResponseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Year;

@RestController
@RequiredArgsConstructor
public class DashboardController {

    private final ProfitLossService profitLossService;

    /**
     * GET /api/lahan/{lahanId}/profit-loss?year=YYYY
     * Returns 12-month P&L breakdown plus annual summary for one lahan.
     */
    @GetMapping("/api/lahan/{lahanId}/profit-loss")
    public ResponseEntity<ApiResponse<ProfitLossResponse>> profitLoss(
            @PathVariable Long lahanId,
            @RequestParam(defaultValue = "0") Integer year,
            @AuthenticationPrincipal User user) {
        int resolvedYear = (year == null || year == 0) ? Year.now().getValue() : year;
        return ResponseUtil.ok(
                profitLossService.computeForLahan(user.getId(), lahanId, resolvedYear));
    }

    /**
     * GET /api/portfolio?year=YYYY
     * Returns one row per lahan with KPI summary for the authenticated user.
     */
    @GetMapping("/api/portfolio")
    public ResponseEntity<ApiResponse<PortfolioResponse>> portfolio(
            @RequestParam(defaultValue = "0") Integer year,
            @AuthenticationPrincipal User user) {
        int resolvedYear = (year == null || year == 0) ? Year.now().getValue() : year;
        return ResponseUtil.ok(
                profitLossService.computeForUser(user.getId(), resolvedYear));
    }
}
