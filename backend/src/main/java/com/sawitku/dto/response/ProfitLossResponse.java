package com.sawitku.dto.response;

import java.util.List;
import java.util.Map;

public record ProfitLossResponse(
        Integer tahun,
        Double totalRevenue,
        Double totalExpenses,
        Double netProfit,
        Double profitMargin,
        List<MonthlyProfitLoss> monthly,
        Map<String, Double> expensesByKategori
) {
    public record MonthlyProfitLoss(
            Integer bulanAngka,
            String bulan,
            Double revenue,
            Double expenses,
            Double profit,
            Double tonAktual
    ) {}
}
