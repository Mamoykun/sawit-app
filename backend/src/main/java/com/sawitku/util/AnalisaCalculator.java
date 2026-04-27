package com.sawitku.util;

import com.sawitku.entity.StatusPanen;
import java.math.BigDecimal;
import java.math.RoundingMode;

public class AnalisaCalculator {

    public record TargetPanen(BigDecimal min, BigDecimal max, BigDecimal mid, String fase) {}

    public static TargetPanen getTarget(double luasHa, int usia) {
        double minPerHa, maxPerHa;
        String fase;
        if (usia < 3)        { minPerHa = 0.3; maxPerHa = 0.8; fase = "Belum Produksi"; }
        else if (usia <= 5)  { minPerHa = 0.8; maxPerHa = 1.4; fase = "Produksi Awal"; }
        else if (usia <= 10) { minPerHa = 1.5; maxPerHa = 2.0; fase = "Puncak Awal"; }
        else if (usia <= 15) { minPerHa = 1.8; maxPerHa = 2.3; fase = "Puncak Produktif"; }
        else if (usia <= 20) { minPerHa = 1.5; maxPerHa = 1.9; fase = "Produksi Stabil"; }
        else                 { minPerHa = 1.0; maxPerHa = 1.5; fase = "Produksi Menurun"; }

        BigDecimal min = BigDecimal.valueOf(minPerHa * luasHa).setScale(2, RoundingMode.HALF_UP);
        BigDecimal max = BigDecimal.valueOf(maxPerHa * luasHa).setScale(2, RoundingMode.HALF_UP);
        BigDecimal mid = min.add(max).divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP);
        return new TargetPanen(min, max, mid, fase);
    }

    public static StatusPanen getStatus(BigDecimal tonAktual, BigDecimal targetMin, BigDecimal targetMid) {
        if (tonAktual.compareTo(targetMin) >= 0) return StatusPanen.NORMAL;
        BigDecimal persen = hitungPersenKurang(tonAktual, targetMid);
        return persen.compareTo(BigDecimal.valueOf(20)) <= 0 ? StatusPanen.WARN : StatusPanen.DANGER;
    }

    public static BigDecimal hitungPersenKurang(BigDecimal tonAktual, BigDecimal targetMid) {
        if (targetMid.compareTo(BigDecimal.ZERO) == 0) return BigDecimal.ZERO;
        BigDecimal diff = targetMid.subtract(tonAktual);
        if (diff.compareTo(BigDecimal.ZERO) <= 0) return BigDecimal.ZERO;
        return diff.divide(targetMid, 4, RoundingMode.HALF_UP)
                   .multiply(BigDecimal.valueOf(100))
                   .setScale(2, RoundingMode.HALF_UP);
    }
}
