package com.sawitku.service;

import com.sawitku.dto.response.AnalisaResponse;
import com.sawitku.entity.Biaya;
import com.sawitku.entity.KategoriBiaya;
import com.sawitku.entity.Lahan;
import com.sawitku.entity.Panen;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class LocalAdvisorService {

    /** Build analisa fallback using only rules — no AI calls. */
    public ClaudeService.AnalisaResult buildFallback(Panen panen, Lahan lahan,
                                                     List<Panen> history,
                                                     List<Biaya> recentBiaya) {
        List<AnalisaResponse.PenyebabItem> penyebab = new ArrayList<>();

        double persenKurang = panen.getPersenKurang() != null
                ? panen.getPersenKurang().doubleValue() : 0.0;
        boolean isNormal = panen.getStatusPanen() != null
                && "NORMAL".equalsIgnoreCase(panen.getStatusPanen().name());

        // Last pupuk biaya
        Optional<Biaya> lastPupuk = recentBiaya.stream()
                .filter(b -> b.getKategori() != null
                        && KategoriBiaya.PUPUK.equals(b.getKategori()))
                .max((a, b) -> Integer.compare(
                        a.getTahun() * 12 + a.getBulanAngka(),
                        b.getTahun() * 12 + b.getBulanAngka()));

        // Rule 1: Belum ada pupuk + defisit
        if (persenKurang > 8 && lastPupuk.isEmpty()) {
            penyebab.add(item("eco", "Belum Ada Catatan Pemupukan",
                    "Tidak ada riwayat pemupukan tercatat. Aplikasikan NPK 16-16-16 dosis 1-2kg/pohon.",
                    "high"));
        }
        // Rule 2: Pupuk terlambat
        else if (persenKurang > 8 && lastPupuk.isPresent()) {
            int monthsAgo = monthsBetween(lastPupuk.get(), panen);
            if (monthsAgo > 4) {
                penyebab.add(item("eco", "Pemupukan Terlambat",
                        String.format("Pemupukan terakhir %d bulan lalu. Sawit fase produksi butuh siklus 3-4 bulan.", monthsAgo),
                        "medium"));
            }
        }

        // Rule 3: Tren turun 3 bulan
        if (history.size() >= 3 && isDecreasingTrend(history)) {
            penyebab.add(item("warning", "Tren Penurunan Konsisten",
                    "Hasil panen menurun 3 bulan berturut-turut. Periksa: defisiensi nutrisi, hama, atau Ganoderma.",
                    "high"));
        }

        // Rule 4: Defisit signifikan
        if (persenKurang > 20) {
            penyebab.add(item("bug", "Kemungkinan Hama atau Penyakit",
                    "Defisit > 20%. Periksa ulat api, kumbang badak, atau pembusukan akar (Ganoderma).",
                    "medium"));
        }

        // Rule 5: Defisit ekstrim
        if (persenKurang > 35) {
            penyebab.add(item("warning", "Audit Manajemen Diperlukan",
                    "Defisit > 35% sangat besar. Audit jadwal pemupukan, pemangkasan (40-48 pelepah aktif), drainase.",
                    "high"));
        }

        // Rule 6: Variasi musiman
        if (persenKurang > 0 && persenKurang <= 8) {
            penyebab.add(item("thermostat", "Variasi Musiman Normal",
                    "Defisit kecil 1-8% wajar dari siklus alami. Pantau bulan berikutnya.",
                    "low"));
        }

        // Rule 7: Normal
        if (penyebab.isEmpty() && isNormal) {
            penyebab.add(item("eco", "Performa Sesuai Target",
                    "Kebun produktif dalam range normal. Pertahankan pemupukan rutin tiap 3-4 bulan.",
                    "low"));
        }

        String ringkasan = isNormal
                ? "Panen sesuai target, kebun dalam kondisi sehat."
                : String.format("Panen kurang %.0f%% dari target minimum.", persenKurang);

        String prioritas = penyebab.isEmpty()
                ? "Lanjutkan pengelolaan rutin."
                : penyebab.get(0).getDetail();

        return new ClaudeService.AnalisaResult(penyebab, ringkasan, prioritas);
    }

    private AnalisaResponse.PenyebabItem item(String icon, String title, String detail, String severity) {
        return AnalisaResponse.PenyebabItem.builder()
                .icon(icon).title(title).detail(detail).severity(severity).estimasiDampak("").build();
    }

    private boolean isDecreasingTrend(List<Panen> history) {
        if (history.size() < 3) return false;
        for (int i = 0; i < 2; i++) {
            if (history.get(i).getTonAktual().compareTo(history.get(i + 1).getTonAktual()) >= 0) return false;
        }
        return true;
    }

    private int monthsBetween(Biaya from, Panen to) {
        return (to.getTahun() * 12 + to.getBulanAngka()) - (from.getTahun() * 12 + from.getBulanAngka());
    }
}
