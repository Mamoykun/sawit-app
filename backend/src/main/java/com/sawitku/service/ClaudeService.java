package com.sawitku.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.dto.response.AnalisaResponse;
import com.sawitku.entity.*;
import com.sawitku.repository.AnalisaRepository;
import com.sawitku.repository.BiayaRepository;
import com.sawitku.repository.PanenRepository;
import com.sawitku.util.AnalisaCalculator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
public class ClaudeService {

    private final AnalisaRepository analisaRepository;
    private final SubscriptionService subscriptionService;
    private final ObjectMapper objectMapper;
    private final PanenRepository panenRepository;
    private final BiayaRepository biayaRepository;
    private final WeatherService weatherService;

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private RedisTemplate<String, String> redisTemplate;

    public ClaudeService(AnalisaRepository analisaRepository,
                         SubscriptionService subscriptionService,
                         ObjectMapper objectMapper,
                         PanenRepository panenRepository,
                         BiayaRepository biayaRepository,
                         WeatherService weatherService) {
        this.analisaRepository = analisaRepository;
        this.subscriptionService = subscriptionService;
        this.objectMapper = objectMapper;
        this.panenRepository = panenRepository;
        this.biayaRepository = biayaRepository;
        this.weatherService = weatherService;
    }

    @Value("${claude.api-key}")
    private String apiKey;

    @Value("${claude.model}")
    private String model;

    @Value("${claude.max-tokens}")
    private int maxTokens;

    private static final String CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";

    @Async
    public void analyzePanen(Panen panen, Lahan lahan) {
        String cacheKey = "analisa:" + panen.getId();
        try {
            subscriptionService.checkLimitAnalisaAI(lahan.getUser().getId());
            String prompt = buildPrompt(panen, lahan);
            String rawResponse = callClaudeApi(prompt);
            AnalisaResult result = parseResponse(rawResponse);
            saveAnalisa(panen, lahan, result, rawResponse);
            subscriptionService.incrementAnalisaCount(lahan.getUser().getId());
            if (redisTemplate != null) redisTemplate.opsForValue().set(cacheKey, "DONE", 7, TimeUnit.DAYS);
        } catch (Exception e) {
            log.error("Claude API error untuk panen {}: {}", panen.getId(), e.getMessage());
            saveFallbackAnalisa(panen, lahan);
            if (redisTemplate != null) redisTemplate.opsForValue().set(cacheKey, "DONE", 7, TimeUnit.DAYS);
        }
    }

    private String buildPrompt(Panen panen, Lahan lahan) {
        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        StringBuilder sb = new StringBuilder();

        sb.append("Kamu adalah ahli agronomi perkebunan sawit Indonesia berpengalaman 20 tahun.\n\n");

        // --- Base: kebun profile ---
        sb.append("Data kebun:\n");
        sb.append("- Nama lahan: ").append(lahan.getNamaLahan()).append("\n");
        sb.append("- Luas: ").append(lahan.getLuasHa()).append(" hektar\n");
        sb.append("- Usia pohon: ").append(lahan.getUsiaPohon()).append(" tahun\n");
        sb.append("- Fase produksi: ").append(target.fase()).append("\n");
        sb.append("- Lokasi: ").append(lahan.getLokasi() != null ? lahan.getLokasi() : "Tidak diketahui").append("\n\n");

        // --- Base: current panen ---
        sb.append("Data panen ").append(panen.getBulan()).append(" ").append(panen.getTahun()).append(":\n");
        sb.append("- Hasil aktual: ").append(panen.getTonAktual()).append(" ton\n");
        sb.append("- Target normal: ").append(panen.getTargetMin()).append(" - ").append(panen.getTargetMax()).append(" ton\n");
        sb.append("- Kekurangan: ").append(panen.getPersenKurang()).append("% dari target\n");

        // --- Optional: panen trend (last 6 months, skip if size < 2) ---
        try {
            List<Panen> riwayat = panenRepository.findByLahanIdOrderByTahunDescBulanAngkaDesc(
                lahan.getId(), PageRequest.of(0, 6));
            // Filter out the current panen entry itself
            List<Panen> history = riwayat.stream()
                .filter(p -> !p.getId().equals(panen.getId()))
                .toList();
            if (history.size() >= 1) {
                sb.append("\nTren panen ").append(history.size()).append(" bulan terakhir:\n");
                for (Panen p : history) {
                    double aktual = p.getTonAktual().doubleValue();
                    double minT = p.getTargetMin().doubleValue();
                    double maxT = p.getTargetMax().doubleValue();
                    double kurang = p.getPersenKurang() != null ? p.getPersenKurang().doubleValue() : 0;
                    String status;
                    if (aktual >= minT) {
                        status = "✓";
                    } else if (kurang <= 20) {
                        status = "⚠";
                    } else {
                        status = "❌";
                    }
                    sb.append("- ").append(p.getBulan()).append(" ").append(p.getTahun())
                      .append(": ").append(p.getTonAktual()).append(" ton")
                      .append(" (target ").append(p.getTargetMin()).append("-").append(p.getTargetMax()).append(")")
                      .append(" ").append(status).append("\n");
                }
            }
        } catch (Exception e) {
            log.debug("Gagal memuat riwayat panen untuk prompt: {}", e.getMessage());
        }

        // --- Optional: fertilizer history (last 6 months) ---
        try {
            LocalDate now = LocalDate.now();
            LocalDate since = now.minusMonths(6);
            List<Biaya> pupuk = biayaRepository.findByLahanIdAndKategoriRecent(
                lahan.getId(), KategoriBiaya.PUPUK, since.getYear(), since.getMonthValue());
            if (!pupuk.isEmpty()) {
                sb.append("\nRiwayat pemupukan ").append(Math.min(pupuk.size(), 6)).append(" bulan terakhir:\n");
                int limit = Math.min(pupuk.size(), 6);
                for (int i = 0; i < limit; i++) {
                    Biaya b = pupuk.get(i);
                    String keterangan = (b.getKeterangan() != null && !b.getKeterangan().isBlank())
                        ? b.getKeterangan() : "Pupuk";
                    sb.append("- ").append(b.getBulan()).append(" ").append(b.getTahun())
                      .append(": ").append(keterangan)
                      .append(" Rp ").append(String.format("%,.0f", b.getJumlah().doubleValue()))
                      .append("\n");
                }
            }
        } catch (Exception e) {
            log.debug("Gagal memuat riwayat pemupukan untuk prompt: {}", e.getMessage());
        }

        // --- Optional: weather summary ---
        try {
            Optional<WeatherService.WeatherSummary> weatherOpt = weatherService.getSummary(lahan.getLokasi());
            weatherOpt.ifPresent(ws -> {
                String lokasiDisplay = lahan.getLokasi() != null ? lahan.getLokasi() : "lokasi ini";
                sb.append("\nCuaca 90 hari terakhir di ").append(lokasiDisplay).append(":\n");
                sb.append("- Total curah hujan: ").append(ws.totalRainfall90d()).append(" mm\n");
                sb.append("- Suhu rata-rata: ").append(ws.avgTemp90d()).append("°C\n");
                sb.append("- Hari kering berturut-turut: ").append(ws.dryDayStreak()).append(" hari\n");
                sb.append("- Hari hujan: ").append(ws.wetDays()).append(" hari\n");
            });
        } catch (Exception e) {
            log.debug("Gagal memuat data cuaca untuk prompt: {}", e.getMessage());
        }

        sb.append("\n");
        sb.append("Analisa penyebab mengapa panen di bawah target dan berikan rekomendasi spesifik.\n");
        sb.append("Gunakan tren panen, riwayat pemupukan, dan data cuaca jika tersedia untuk meningkatkan akurasi analisa.\n");
        sb.append("Balas HANYA dengan JSON valid (tanpa markdown/backtick):\n");
        sb.append("{\"penyebab\":[{\"icon\":\"<ICON_KEY>\",\"title\":\"judul singkat\",\"detail\":\"penjelasan + rekomendasi 2-3 kalimat\",\"severity\":\"high|medium|low\",\"estimasi_dampak\":\"X-Y% penurunan\"}],\"ringkasan\":\"ringkasan 1 kalimat\",\"prioritas_tindakan\":\"tindakan paling penting minggu ini\"}\n\n");
        sb.append("<ICON_KEY> harus salah satu dari: \"eco\" (nutrisi/pupuk/gulma), \"water\" (air/kekeringan/drainase), \"bug\" (hama/penyakit), \"thermostat\" (cuaca/musim), \"warning\" (manajemen/lainnya). JANGAN gunakan emoji.\n");

        return sb.toString();
    }

    private String callClaudeApi(String prompt) {
        RestTemplate rest = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.set("x-api-key", apiKey);
        headers.set("anthropic-version", "2023-06-01");
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = Map.of(
            "model", model,
            "max_tokens", maxTokens,
            "messages", List.of(Map.of("role", "user", "content", prompt))
        );

        ResponseEntity<Map> response = rest.exchange(
            CLAUDE_API_URL, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);

        List<Map<String, Object>> content = (List<Map<String, Object>>) response.getBody().get("content");
        return (String) content.get(0).get("text");
    }

    private record AnalisaResult(List<AnalisaResponse.PenyebabItem> penyebab, String ringkasan, String prioritas) {}

    private AnalisaResult parseResponse(String raw) throws Exception {
        Map<String, Object> parsed = objectMapper.readValue(raw.trim(), Map.class);
        List<Map<String, Object>> penyebabList = (List<Map<String, Object>>) parsed.get("penyebab");
        List<AnalisaResponse.PenyebabItem> items = penyebabList.stream()
            .map(p -> AnalisaResponse.PenyebabItem.builder()
                .icon((String) p.get("icon")).title((String) p.get("title"))
                .detail((String) p.get("detail")).severity((String) p.get("severity"))
                .estimasiDampak((String) p.getOrDefault("estimasi_dampak", "")).build())
            .toList();
        return new AnalisaResult(items, (String) parsed.get("ringkasan"), (String) parsed.get("prioritas_tindakan"));
    }

    private void saveAnalisa(Panen panen, Lahan lahan, AnalisaResult result, String raw) throws Exception {
        String penyebabJson = objectMapper.writeValueAsString(result.penyebab());
        Analisa analisa = Analisa.builder()
            .panen(panen).lahan(lahan)
            .penyebabJson(penyebabJson)
            .rekomendasi(result.prioritas())
            .aiResponseRaw(raw)
            .createdAt(LocalDateTime.now()).build();
        analisaRepository.save(analisa);
    }

    private void saveFallbackAnalisa(Panen panen, Lahan lahan) {
        try {
            double persen = panen.getPersenKurang().doubleValue();
            List<AnalisaResponse.PenyebabItem> items = getFallbackPenyebab(persen);
            String penyebabJson = objectMapper.writeValueAsString(items);
            Analisa analisa = Analisa.builder()
                .panen(panen).lahan(lahan)
                .penyebabJson(penyebabJson)
                .rekomendasi("Periksa kondisi lahan dan lakukan tindakan pemupukan rutin.")
                .aiResponseRaw("FALLBACK")
                .createdAt(LocalDateTime.now()).build();
            analisaRepository.save(analisa);
        } catch (Exception e) {
            log.error("Fallback analisa gagal: {}", e.getMessage());
        }
    }

    private List<AnalisaResponse.PenyebabItem> getFallbackPenyebab(double persen) {
        List<AnalisaResponse.PenyebabItem> list = new ArrayList<>();
        if (persen > 8) list.add(item("eco", "Defisiensi Kalium (K)", "Aplikasikan pupuk MOP 0.5–1 kg per pohon. Kalium meningkatkan bobot tandan dan kualitas minyak sawit.", "high", "8-15%"));
        if (persen > 15) list.add(item("water", "Stres Kekeringan", "Pasang mulsa pelepah di piringan pohon radius 2 meter untuk menjaga kelembaban tanah di musim kering.", "high", "10-20%"));
        if (persen > 20) list.add(item("bug", "Serangan Hama / Penyakit", "Periksa tanda ulat api, kumbang badak, atau gejala Ganoderma di pangkal batang pohon.", "medium", "5-15%"));
        if (list.isEmpty()) list.add(item("thermostat", "Faktor Musiman Normal", "Fluktuasi 1–8% masih dalam batas wajar akibat perubahan cuaca dan siklus alami tanaman sawit.", "low", "1-8%"));
        return list;
    }

    private AnalisaResponse.PenyebabItem item(String icon, String title, String detail, String severity, String dampak) {
        return AnalisaResponse.PenyebabItem.builder()
            .icon(icon).title(title).detail(detail).severity(severity).estimasiDampak(dampak).build();
    }

    // ─── VISUAL DIAGNOSA (Claude Vision) ─────────────────────────────────────

    public record VisualDiagnosaResult(
        String kondisi, String penyebab, String rekomendasi,
        String severity, boolean isFallback) {}

    public VisualDiagnosaResult analyzeImage(String imageBase64, String jenis,
                                              com.sawitku.entity.Lahan lahan) {
        try {
            String prompt = buildVisualPrompt(jenis, lahan);
            String rawResponse = callClaudeVisionApi(prompt, imageBase64);
            return parseVisualResponse(rawResponse);
        } catch (Exception e) {
            log.error("Claude Vision error untuk jenis {}: {}", jenis, e.getMessage());
            return getFallbackVisualResult(jenis);
        }
    }

    private String buildVisualPrompt(String jenis, com.sawitku.entity.Lahan lahan) {
        String konteks = "Konteks kebun: luas %s ha, usia pohon %d tahun".formatted(
            lahan.getLuasHa(), lahan.getUsiaPohon());
        String fokus = switch (jenis) {
            case "BUAH" -> "Foto ini adalah BUAH/TANDAN sawit. Fokus pada: kematangan (mentah/matang/lewat matang), warna brondolan, ukuran tandan, kerusakan fisik, indikasi serangan hama.";
            case "BATANG" -> "Foto ini adalah BATANG/POHON sawit. Fokus pada: kondisi pangkal batang, tanda penyakit Ganoderma (jamur putih/akar busuk), kerusakan kumbang, retak/luka.";
            case "PELEPAH" -> "Foto ini adalah PELEPAH/DAUN sawit. Fokus pada: warna daun (defisiensi nutrisi), bercak penyakit, serangan ulat api, kekurangan air, gejala defisiensi Mg/N/K.";
            default -> "Analisa kondisi tanaman sawit pada foto ini.";
        };
        return """
            Kamu adalah ahli agronomi sawit Indonesia berpengalaman 20 tahun.
            %s
            %s

            LANGKAH 1 — VALIDASI FOTO:
            Pertama, pastikan foto ini adalah tanaman kelapa sawit (Elaeis guineensis).
            Jika foto BUKAN tanaman sawit (misal: tanaman lain, manusia, hewan, objek non-tanaman,
            screenshot, gambar acak), kembalikan JSON ini tepat:
            {"kondisi":"BUKAN_SAWIT","penyebab":"","rekomendasi":"","severity":"NORMAL"}

            LANGKAH 2 — JIKA FOTO ADALAH SAWIT:
            Berikan analisa dalam format JSON valid (tanpa markdown/backtick):
            {"kondisi":"deskripsi 1-2 kalimat apa yang terlihat di foto","penyebab":"kemungkinan penyebab atau identifikasi 1-2 kalimat","rekomendasi":"tindakan konkret yang harus dilakukan petani 2-3 kalimat","severity":"NORMAL|PERHATIAN|KRITIS"}

            Pedoman severity:
            - NORMAL: kondisi baik, tidak ada masalah
            - PERHATIAN: ada gejala awal yang perlu dipantau
            - KRITIS: butuh tindakan segera, ada kerugian signifikan
            """.formatted(konteks, fokus);
    }

    @SuppressWarnings("unchecked")
    private String callClaudeVisionApi(String prompt, String imageBase64) {
        RestTemplate rest = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.set("x-api-key", apiKey);
        headers.set("anthropic-version", "2023-06-01");
        headers.setContentType(MediaType.APPLICATION_JSON);

        String mediaType = imageBase64.startsWith("/9j/") ? "image/jpeg"
                          : imageBase64.startsWith("iVBOR") ? "image/png"
                          : "image/jpeg";

        Map<String, Object> imageContent = Map.of(
            "type", "image",
            "source", Map.of(
                "type", "base64",
                "media_type", mediaType,
                "data", imageBase64
            )
        );
        Map<String, Object> textContent = Map.of("type", "text", "text", prompt);

        Map<String, Object> body = Map.of(
            "model", model,
            "max_tokens", maxTokens,
            "messages", List.of(Map.of(
                "role", "user",
                "content", List.of(imageContent, textContent)
            ))
        );

        ResponseEntity<Map> response = rest.exchange(
            CLAUDE_API_URL, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);

        List<Map<String, Object>> content = (List<Map<String, Object>>) response.getBody().get("content");
        return (String) content.get(0).get("text");
    }

    @SuppressWarnings("unchecked")
    private VisualDiagnosaResult parseVisualResponse(String raw) throws Exception {
        Map<String, Object> parsed = objectMapper.readValue(raw.trim(), Map.class);
        String severity = (String) parsed.getOrDefault("severity", "NORMAL");
        if (!List.of("NORMAL", "PERHATIAN", "KRITIS").contains(severity)) severity = "NORMAL";
        return new VisualDiagnosaResult(
            (String) parsed.getOrDefault("kondisi", ""),
            (String) parsed.getOrDefault("penyebab", ""),
            (String) parsed.getOrDefault("rekomendasi", ""),
            severity, false
        );
    }

    private VisualDiagnosaResult getFallbackVisualResult(String jenis) {
        return switch (jenis) {
            case "BUAH" -> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto secara otomatis saat ini.",
                "Layanan diagnosa AI sedang sibuk atau gambar tidak jelas.",
                "Pastikan panen saat tandan matang penuh: brondolan jatuh 5-10 buah/tandan, warna oranye-kemerahan, tandan padat. Hindari panen mentah karena rendemen minyak rendah.",
                "PERHATIAN", true);
            case "BATANG" -> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto secara otomatis saat ini.",
                "Layanan diagnosa AI sedang sibuk atau gambar tidak jelas.",
                "Periksa pangkal batang dari tanda Ganoderma (jamur putih, akar busuk berwarna coklat). Jika ada gejala, isolasi pohon dan konsultasi penyuluh. Hindari pelukaan batang saat panen.",
                "PERHATIAN", true);
            case "PELEPAH" -> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto secara otomatis saat ini.",
                "Layanan diagnosa AI sedang sibuk atau gambar tidak jelas.",
                "Pelepah menguning bisa menandakan defisiensi: Mg (menguning antar tulang daun), N (menguning seluruh daun), atau K (bercak oranye di pinggir). Aplikasikan pupuk sesuai gejala dan dosis standar PPKS.",
                "PERHATIAN", true);
            default -> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto.",
                "Foto tidak teridentifikasi.",
                "Coba ambil foto lebih jelas dengan pencahayaan cukup.",
                "NORMAL", true);
        };
    }
}
