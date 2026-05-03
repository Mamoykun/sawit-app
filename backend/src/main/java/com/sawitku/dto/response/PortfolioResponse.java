package com.sawitku.dto.response;

import java.util.List;

public record PortfolioResponse(
        Integer tahun,
        Double totalRevenue,
        Double totalExpenses,
        Double netProfit,
        Integer totalLahan,
        Double totalLuasHa,
        List<LahanSummary> lahans
) {
    public record LahanSummary(
            Long lahanId,
            String namaLahan,
            Double luasHa,
            Integer usiaPohon,
            String fase,
            Double revenue,
            Double expenses,
            Double profit,
            Double profitPerHa,
            Double avgTonPerHa,
            Integer panenCount,
            String latestStatusPanen
    ) {}
}
