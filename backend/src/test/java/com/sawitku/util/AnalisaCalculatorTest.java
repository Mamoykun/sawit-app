package com.sawitku.util;

import com.sawitku.entity.StatusPanen;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class AnalisaCalculatorTest {

    @Test
    void getTarget_usiaBelumProduksi() {
        var result = AnalisaCalculator.getTarget(2.0, 2);
        assertThat(result.min()).isEqualByComparingTo(new java.math.BigDecimal("0.60"));
        assertThat(result.max()).isEqualByComparingTo(new java.math.BigDecimal("1.60"));
        assertThat(result.fase()).isEqualTo("Belum Produksi");
    }

    @Test
    void getTarget_usiaPuncakProduktif() {
        var result = AnalisaCalculator.getTarget(2.0, 12);
        assertThat(result.min()).isEqualByComparingTo(new java.math.BigDecimal("3.60"));
        assertThat(result.max()).isEqualByComparingTo(new java.math.BigDecimal("4.60"));
        assertThat(result.fase()).isEqualTo("Puncak Produktif");
    }

    @Test
    void getStatusPanen_normal() {
        assertThat(AnalisaCalculator.getStatus(
            new java.math.BigDecimal("3.0"),
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        )).isEqualTo(StatusPanen.NORMAL);
    }

    @Test
    void getStatusPanen_warn() {
        assertThat(AnalisaCalculator.getStatus(
            new java.math.BigDecimal("1.5"),
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        )).isEqualTo(StatusPanen.WARN);
    }

    @Test
    void getStatusPanen_danger() {
        assertThat(AnalisaCalculator.getStatus(
            new java.math.BigDecimal("1.0"),
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        )).isEqualTo(StatusPanen.DANGER);
    }

    @Test
    void hitungPersenKurang_positif() {
        var result = AnalisaCalculator.hitungPersenKurang(
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        );
        assertThat(result).isEqualByComparingTo(new java.math.BigDecimal("20.00"));
    }

    @Test
    void hitungPersenKurang_nolKalauMelebihiTarget() {
        var result = AnalisaCalculator.hitungPersenKurang(
            new java.math.BigDecimal("3.0"),
            new java.math.BigDecimal("2.5")
        );
        assertThat(result).isEqualByComparingTo(java.math.BigDecimal.ZERO);
    }
}
