package com.sawitku.service;

import com.sawitku.dto.response.PortfolioResponse;
import com.sawitku.dto.response.ProfitLossResponse;
import com.sawitku.entity.KategoriBiaya;
import com.sawitku.entity.Lahan;
import com.sawitku.exception.ResourceNotFoundException;
import com.sawitku.repository.BiayaRepository;
import com.sawitku.repository.LahanRepository;
import com.sawitku.repository.PanenRepository;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ProfitLossService {

    private static final String[] BULAN_NAMES = {
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    };

    private final PanenRepository panenRepository;
    private final BiayaRepository biayaRepository;
    private final LahanRepository lahanRepository;

    /**
     * Compute P&L for a single lahan for the given year.
     * Verifies ownership before querying.
     */
    public ProfitLossResponse computeForLahan(Long userId, Long lahanId, Integer tahun) {
        // Security: verify lahan belongs to the authenticated user
        lahanRepository.findByIdAndUserId(lahanId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        // --- Panen aggregation ---
        // row: [bulanAngka(Integer), sumTon(BigDecimal), sumRevenue(BigDecimal)]
        List<Object[]> panenRows = panenRepository.sumByMonth(lahanId, tahun);
        Map<Integer, double[]> panenByMonth = new HashMap<>(); // key=bulanAngka, value=[ton, revenue]
        for (Object[] row : panenRows) {
            int bulan = ((Number) row[0]).intValue();
            double ton = row[1] != null ? ((Number) row[1]).doubleValue() : 0.0;
            double rev = row[2] != null ? ((Number) row[2]).doubleValue() : 0.0;
            panenByMonth.put(bulan, new double[]{ton, rev});
        }

        // --- Biaya aggregation by month ---
        // row: [bulanAngka(Integer), sumJumlah(BigDecimal)]
        List<Object[]> biayaRows = biayaRepository.sumByMonth(lahanId, tahun);
        Map<Integer, Double> biayaByMonth = new HashMap<>();
        for (Object[] row : biayaRows) {
            int bulan = ((Number) row[0]).intValue();
            double jumlah = row[1] != null ? ((Number) row[1]).doubleValue() : 0.0;
            biayaByMonth.put(bulan, jumlah);
        }

        // --- Biaya aggregation by kategori ---
        // row: [kategori(KategoriBiaya), sumJumlah(BigDecimal)]
        List<Object[]> kategoriRows = biayaRepository.sumByKategori(lahanId, tahun);
        Map<String, Double> expensesByKategori = new LinkedHashMap<>();
        // Pre-fill all enum values with zero
        for (KategoriBiaya k : KategoriBiaya.values()) {
            expensesByKategori.put(k.name(), 0.0);
        }
        for (Object[] row : kategoriRows) {
            KategoriBiaya kat = (KategoriBiaya) row[0];
            double jumlah = row[1] != null ? ((Number) row[1]).doubleValue() : 0.0;
            expensesByKategori.put(kat.name(), jumlah);
        }

        // --- Build 12-month list ---
        List<ProfitLossResponse.MonthlyProfitLoss> monthly = new ArrayList<>();
        double totalRevenue = 0.0;
        double totalExpenses = 0.0;

        for (int m = 1; m <= 12; m++) {
            double[] panenData = panenByMonth.getOrDefault(m, new double[]{0.0, 0.0});
            double ton = panenData[0];
            double revenue = panenData[1];
            double expenses = biayaByMonth.getOrDefault(m, 0.0);
            double profit = revenue - expenses;

            totalRevenue += revenue;
            totalExpenses += expenses;

            monthly.add(new ProfitLossResponse.MonthlyProfitLoss(
                    m,
                    BULAN_NAMES[m - 1],
                    revenue,
                    expenses,
                    profit,
                    ton
            ));
        }

        double netProfit = totalRevenue - totalExpenses;
        Double profitMargin = totalRevenue > 0
                ? (netProfit / totalRevenue) * 100.0
                : null;

        return new ProfitLossResponse(
                tahun,
                totalRevenue,
                totalExpenses,
                netProfit,
                profitMargin,
                monthly,
                expensesByKategori
        );
    }

    /**
     * Compute portfolio summary for all active lahan owned by the user.
     */
    public PortfolioResponse computeForUser(Long userId, Integer tahun) {
        List<Lahan> lahans = lahanRepository.findByUserIdAndIsActiveTrue(userId);

        int currentYear = LocalDate.now().getYear();
        double totalRevenue = 0.0;
        double totalExpenses = 0.0;
        double totalLuasHa = 0.0;
        List<PortfolioResponse.LahanSummary> summaries = new ArrayList<>();

        for (Lahan lahan : lahans) {
            totalLuasHa += lahan.getLuasHa().doubleValue();

            // Panen aggregation
            List<Object[]> panenRows = panenRepository.sumByMonth(lahan.getId(), tahun);
            double lahanRevenue = 0.0;
            double totalTon = 0.0;
            for (Object[] row : panenRows) {
                double rev = row[2] != null ? ((Number) row[2]).doubleValue() : 0.0;
                double ton = row[1] != null ? ((Number) row[1]).doubleValue() : 0.0;
                lahanRevenue += rev;
                totalTon += ton;
            }
            int panenCount = panenRows.size(); // months with panen

            // Biaya aggregation
            List<Object[]> biayaRows = biayaRepository.sumByMonth(lahan.getId(), tahun);
            double lahanExpenses = 0.0;
            for (Object[] row : biayaRows) {
                double jumlah = row[1] != null ? ((Number) row[1]).doubleValue() : 0.0;
                lahanExpenses += jumlah;
            }

            double lahanProfit = lahanRevenue - lahanExpenses;
            double luasHa = lahan.getLuasHa().doubleValue();
            double profitPerHa = luasHa > 0 ? lahanProfit / luasHa : 0.0;
            double avgTonPerHa = (luasHa > 0 && panenCount > 0)
                    ? (totalTon / panenCount) / luasHa
                    : 0.0;

            // Determine usia (use tahunTanam if available)
            int usia = lahan.getTahunTanam() != null
                    ? currentYear - lahan.getTahunTanam()
                    : (lahan.getUsiaPohon() != null ? lahan.getUsiaPohon() : 0);
            String fase = AnalisaCalculator.getTarget(luasHa, usia).fase();

            // Latest status panen
            List<String> statusList = panenRepository.findLatestStatusPanen(
                    lahan.getId(), PageRequest.of(0, 1));
            String latestStatus = statusList.isEmpty() ? null : statusList.get(0);

            totalRevenue += lahanRevenue;
            totalExpenses += lahanExpenses;

            summaries.add(new PortfolioResponse.LahanSummary(
                    lahan.getId(),
                    lahan.getNamaLahan(),
                    luasHa,
                    usia,
                    fase,
                    lahanRevenue,
                    lahanExpenses,
                    lahanProfit,
                    profitPerHa,
                    avgTonPerHa,
                    panenCount,
                    latestStatus
            ));
        }

        return new PortfolioResponse(
                tahun,
                totalRevenue,
                totalExpenses,
                totalRevenue - totalExpenses,
                lahans.size(),
                totalLuasHa,
                summaries
        );
    }
}
