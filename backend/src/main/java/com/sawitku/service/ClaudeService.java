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

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
public class ClaudeService {

    // ─── Model routing enum ───────────────────────────────────────────────────
    public enum ClaudeModel { HAIKU, SONNET }

    // ─── Result record (public so LocalAdvisorService can reference it) ───────
    public static record AnalisaResult(
            List<AnalisaResponse.PenyebabItem> penyebab,
            String ringkasan,
            String prioritas) {}

    // ─── Dependencies ─────────────────────────────────────────────────────────
    private final AnalisaRepository analisaRepository;
    private final SubscriptionService subscriptionService;
    private final ObjectMapper objectMapper;
    private final PanenRepository panenRepository;
    private final BiayaRepository biayaRepository;
    private final WeatherService weatherService;
    private final LocalAdvisorService localAdvisorService;
    private final AiUsageService aiUsageService;

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private RedisTemplate<String, String> redisTemplate;

    public ClaudeService(AnalisaRepository analisaRepository,
                         SubscriptionService subscriptionService,
                         ObjectMapper objectMapper,
                         PanenRepository panenRepository,
                         BiayaRepository biayaRepository,
                         WeatherService weatherService,
                         LocalAdvisorService localAdvisorService,
                         AiUsageService aiUsageService) {
        this.analisaRepository = analisaRepository;
        this.subscriptionService = subscriptionService;
        this.objectMapper = objectMapper;
        this.panenRepository = panenRepository;
        this.biayaRepository = biayaRepository;
        this.weatherService = weatherService;
        this.localAdvisorService = localAdvisorService;
        this.aiUsageService = aiUsageService;
    }

    @Value("${claude.api-key}")
    private String apiKey;

    @Value("${claude.model.haiku}")
    private String haikuModel;

    @Value("${claude.model.sonnet}")
    private String sonnetModel;

    @Value("${claude.max-tokens}")
    private int maxTokens;

    @Value("${claude.cache-ttl-days:30}")
    private int cacheTtlDays;

    private static final String CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";

    // ─── Main analysis entry point ────────────────────────────────────────────

    @Async
    public void analyzePanen(Panen panen, Lahan lahan) {
        doAnalyzePanen(panen, lahan);
    }

    /** Synchronous variant for batch upgrade job (same thread, no @Async proxy). */
    public void analyzePanenSync(Panen panen, Lahan lahan) {
        doAnalyzePanen(panen, lahan);
    }

    private void doAnalyzePanen(Panen panen, Lahan lahan) {
        Long userId = lahan.getUser().getId();

        // Build cache key from data hash (not panen.id — allows deduplication)
        String hashInput = String.join("|",
                String.valueOf(panen.getTonAktual()),
                String.valueOf(lahan.getId()),
                String.valueOf(lahan.getUsiaPohon()),
                String.valueOf(panen.getBulanAngka()),
                String.valueOf(panen.getTahun()),
                lahan.getLokasi() != null ? lahan.getLokasi() : "");
        String cacheKey = "analisa:hash:" + sha256Hex(hashInput);

        try {
            // 1. Cache hit check
            if (redisTemplate != null) {
                String cached = redisTemplate.opsForValue().get(cacheKey);
                if (cached != null && cached.length() > 10) {
                    log.debug("Cache hit for panen {} (key={})", panen.getId(), cacheKey);
                    try {
                        AnalisaResult result = parseResponse(cached);
                        saveAnalisa(panen, lahan, result, cached);
                        return;
                    } catch (Exception e) {
                        log.debug("Cache parse failed, proceeding with fresh call: {}", e.getMessage());
                    }
                }
            }

            // 2. Subscription limit check
            subscriptionService.checkLimitAnalisaAI(userId);

            // 3. Budget cap check
            if (!aiUsageService.canSpend(userId)) {
                log.info("User {} exceeded AI budget cap — using local fallback", userId);
                saveFallbackAnalisa(panen, lahan);
                return;
            }

            // 4. Load history for routing
            List<Panen> history = loadHistory(panen, lahan);

            // 5. Build prompt + route model
            String prompt = buildPrompt(panen, lahan);
            ClaudeModel model = selectModelFor(panen, lahan, history);

            // 6. Call Claude
            String rawResponse = callClaudeApi(prompt, model, userId);

            // 7. Parse, save, increment
            AnalisaResult result = parseResponse(rawResponse);
            saveAnalisa(panen, lahan, result, rawResponse);
            subscriptionService.incrementAnalisaCount(userId);

            // 8. Cache raw response
            if (redisTemplate != null) {
                redisTemplate.opsForValue().set(
                        cacheKey, rawResponse,
                        cacheTtlDays * 24L * 60L * 60L, TimeUnit.SECONDS);
            }

        } catch (Exception e) {
            log.error("Claude API error for panen {}: {}", panen.getId(), e.getMessage());
            saveFallbackAnalisa(panen, lahan);
        }
    }

    // ─── Model routing ────────────────────────────────────────────────────────

    public ClaudeModel selectModelFor(Panen panen, Lahan lahan, List<Panen> history) {
        // Simple cases → Haiku (cheaper)
        if (panen.getStatusPanen() == null || StatusPanen.NORMAL == panen.getStatusPanen())
            return ClaudeModel.HAIKU;
        if (history.size() < 3)
            return ClaudeModel.HAIKU;
        if (panen.getPersenKurang() != null && panen.getPersenKurang().doubleValue() < 10.0)
            return ClaudeModel.HAIKU;

        // Complex cases → Sonnet (better reasoning)
        if (panen.getPersenKurang() != null && panen.getPersenKurang().doubleValue() > 25.0)
            return ClaudeModel.SONNET;
        if (history.size() >= 3 && isDecreasingTrend(history))
            return ClaudeModel.SONNET;

        return ClaudeModel.HAIKU;
    }

    private boolean isDecreasingTrend(List<Panen> history) {
        if (history.size() < 3) return false;
        // history is sorted newest-first
        for (int i = 0; i < 2; i++) {
            if (history.get(i).getTonAktual().compareTo(history.get(i + 1).getTonAktual()) >= 0)
                return false;
        }
        return true;
    }

    // ─── Prompt construction ──────────────────────────────────────────────────

    private String buildPrompt(Panen panen, Lahan lahan) {
        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        StringBuilder sb = new StringBuilder();

        sb.append("Kamu adalah ahli agronomi perkebunan sawit Indonesia berpengalaman 20 tahun.\n\n");

        sb.append("Data kebun:\n");
        sb.append("- Nama lahan: ").append(lahan.getNamaLahan()).append("\n");
        sb.append("- Luas: ").append(lahan.getLuasHa()).append(" hektar\n");
        sb.append("- Usia pohon: ").append(lahan.getUsiaPohon()).append(" tahun\n");
        sb.append("- Fase produksi: ").append(target.fase()).append("\n");
        sb.append("- Lokasi: ").append(lahan.getLokasi() != null ? lahan.getLokasi() : "Tidak diketahui").append("\n\n");

        sb.append("Data panen ").append(panen.getBulan()).append(" ").append(panen.getTahun()).append(":\n");
        sb.append("- Hasil aktual: ").append(panen.getTonAktual()).append(" ton\n");
        sb.append("- Target normal: ").append(panen.getTargetMin()).append(" - ").append(panen.getTargetMax()).append(" ton\n");
        sb.append("- Kekurangan: ").append(panen.getPersenKurang()).append("% dari target\n");

        // Panen trend
        try {
            List<Panen> riwayat = panenRepository.findByLahanIdOrderByTahunDescBulanAngkaDesc(
                    lahan.getId(), PageRequest.of(0, 6));
            List<Panen> history = riwayat.stream()
                    .filter(p -> !p.getId().equals(panen.getId()))
                    .toList();
            if (history.size() >= 1) {
                sb.append("\nTren panen ").append(history.size()).append(" bulan terakhir:\n");
                for (Panen p : history) {
                    double aktual = p.getTonAktual().doubleValue();
                    double minT   = p.getTargetMin().doubleValue();
                    double kurang = p.getPersenKurang() != null ? p.getPersenKurang().doubleValue() : 0;
                    String status = aktual >= minT ? "✓" : kurang <= 20 ? "⚠" : "❌";
                    sb.append("- ").append(p.getBulan()).append(" ").append(p.getTahun())
                      .append(": ").append(p.getTonAktual()).append(" ton")
                      .append(" (target ").append(p.getTargetMin()).append("-").append(p.getTargetMax()).append(")")
                      .append(" ").append(status).append("\n");
                }
            }
        } catch (Exception e) {
            log.debug("Gagal memuat riwayat panen untuk prompt: {}", e.getMessage());
        }

        // Fertilizer history
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
                    String ket = (b.getKeterangan() != null && !b.getKeterangan().isBlank())
                            ? b.getKeterangan() : "Pupuk";
                    sb.append("- ").append(b.getBulan()).append(" ").append(b.getTahun())
                      .append(": ").append(ket)
                      .append(" Rp ").append(String.format("%,.0f", b.getJumlah().doubleValue()))
                      .append("\n");
                }
            }
        } catch (Exception e) {
            log.debug("Gagal memuat riwayat pemupukan untuk prompt: {}", e.getMessage());
        }

        // Weather summary
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

    // ─── Claude API call ──────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private String callClaudeApi(String prompt, ClaudeModel model, Long userId) {
        RestTemplate rest = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.set("x-api-key", apiKey);
        headers.set("anthropic-version", "2023-06-01");
        headers.setContentType(MediaType.APPLICATION_JSON);

        String modelId = model == ClaudeModel.HAIKU ? haikuModel : sonnetModel;

        Map<String, Object> body = Map.of(
                "model", modelId,
                "max_tokens", maxTokens,
                "messages", List.of(Map.of("role", "user", "content", prompt))
        );

        ResponseEntity<Map> response = rest.exchange(
                CLAUDE_API_URL, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);

        @SuppressWarnings("unchecked")
        Map<String, Object> responseBody = (Map<String, Object>) response.getBody();

        // Extract and record token usage
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> usage = (Map<String, Object>) responseBody.get("usage");
            if (usage != null) {
                int inputTokens  = ((Number) usage.getOrDefault("input_tokens",  0)).intValue();
                int outputTokens = ((Number) usage.getOrDefault("output_tokens", 0)).intValue();
                aiUsageService.record(userId, model, inputTokens, outputTokens);
            }
        } catch (Exception e) {
            log.debug("Failed to extract usage from Claude response: {}", e.getMessage());
        }

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> content = (List<Map<String, Object>>) responseBody.get("content");
        return (String) content.get(0).get("text");
    }

    // ─── Response parsing + persistence ──────────────────────────────────────

    @SuppressWarnings("unchecked")
    public AnalisaResult parseResponse(String raw) throws Exception {
        Map<String, Object> parsed = objectMapper.readValue(raw.trim(), Map.class);
        List<Map<String, Object>> penyebabList = (List<Map<String, Object>>) parsed.get("penyebab");
        List<AnalisaResponse.PenyebabItem> items = penyebabList.stream()
                .map(p -> AnalisaResponse.PenyebabItem.builder()
                        .icon((String) p.get("icon"))
                        .title((String) p.get("title"))
                        .detail((String) p.get("detail"))
                        .severity((String) p.get("severity"))
                        .estimasiDampak((String) p.getOrDefault("estimasi_dampak", ""))
                        .build())
                .toList();
        return new AnalisaResult(items,
                (String) parsed.get("ringkasan"),
                (String) parsed.get("prioritas_tindakan"));
    }

    private void saveAnalisa(Panen panen, Lahan lahan, AnalisaResult result, String raw) throws Exception {
        String penyebabJson = objectMapper.writeValueAsString(result.penyebab());
        Analisa analisa = Analisa.builder()
                .panen(panen).lahan(lahan)
                .penyebabJson(penyebabJson)
                .rekomendasi(result.prioritas())
                .aiResponseRaw(raw)
                .createdAt(LocalDateTime.now())
                .build();
        analisaRepository.save(analisa);
    }

    // ─── Fallback (rule-based, no subscription increment) ────────────────────

    private void saveFallbackAnalisa(Panen panen, Lahan lahan) {
        try {
            List<Panen> history = loadHistory(panen, lahan);
            List<Biaya> recentBiaya = loadRecentPupuk(lahan);
            AnalisaResult result = localAdvisorService.buildFallback(panen, lahan, history, recentBiaya);
            saveAnalisa(panen, lahan, result, "{\"source\":\"local_advisor\"}");
        } catch (Exception e) {
            log.error("Fallback analisa gagal: {}", e.getMessage());
        }
    }

    // ─── History + biaya helpers ──────────────────────────────────────────────

    private List<Panen> loadHistory(Panen panen, Lahan lahan) {
        try {
            List<Panen> riwayat = panenRepository.findByLahanIdOrderByTahunDescBulanAngkaDesc(
                    lahan.getId(), PageRequest.of(0, 6));
            return riwayat.stream()
                    .filter(p -> !p.getId().equals(panen.getId()))
                    .toList();
        } catch (Exception e) {
            log.debug("loadHistory failed: {}", e.getMessage());
            return List.of();
        }
    }

    private List<Biaya> loadRecentPupuk(Lahan lahan) {
        try {
            LocalDate since = LocalDate.now().minusMonths(6);
            return biayaRepository.findByLahanIdAndKategoriRecent(
                    lahan.getId(), KategoriBiaya.PUPUK, since.getYear(), since.getMonthValue());
        } catch (Exception e) {
            log.debug("loadRecentPupuk failed: {}", e.getMessage());
            return List.of();
        }
    }

    // ─── SHA-256 cache key helper ─────────────────────────────────────────────

    private String sha256Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            return Integer.toHexString(input.hashCode());
        }
    }

    // ─── VISUAL DIAGNOSA (Claude Vision — always uses sonnet) ─────────────────

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
            case "BUAH"   -> "Foto ini adalah BUAH/TANDAN sawit. Fokus pada: kematangan (mentah/matang/lewat matang), warna brondolan, ukuran tandan, kerusakan fisik, indikasi serangan hama.";
            case "BATANG" -> "Foto ini adalah BATANG/POHON sawit. Fokus pada: kondisi pangkal batang, tanda penyakit Ganoderma (jamur putih/akar busuk), kerusakan kumbang, retak/luka.";
            case "PELEPAH"-> "Foto ini adalah PELEPAH/DAUN sawit. Fokus pada: warna daun (defisiensi nutrisi), bercak penyakit, serangan ulat api, kekurangan air, gejala defisiensi Mg/N/K.";
            default       -> "Analisa kondisi tanaman sawit pada foto ini.";
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

        String mediaType = imageBase64.startsWith("/9j/")   ? "image/jpeg"
                         : imageBase64.startsWith("iVBOR") ? "image/png"
                         : "image/jpeg";

        Map<String, Object> imageContent = Map.of(
                "type", "image",
                "source", Map.of("type", "base64", "media_type", mediaType, "data", imageBase64)
        );
        Map<String, Object> textContent = Map.of("type", "text", "text", prompt);

        // Vision always uses Sonnet (requires vision capability)
        Map<String, Object> body = Map.of(
                "model", sonnetModel,
                "max_tokens", maxTokens,
                "messages", List.of(Map.of("role", "user",
                        "content", List.of(imageContent, textContent)))
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
                severity, false);
    }

    private VisualDiagnosaResult getFallbackVisualResult(String jenis) {
        return switch (jenis) {
            case "BUAH"   -> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto secara otomatis saat ini.",
                "Layanan diagnosa AI sedang sibuk atau gambar tidak jelas.",
                "Pastikan panen saat tandan matang penuh: brondolan jatuh 5-10 buah/tandan, warna oranye-kemerahan, tandan padat. Hindari panen mentah karena rendemen minyak rendah.",
                "PERHATIAN", true);
            case "BATANG" -> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto secara otomatis saat ini.",
                "Layanan diagnosa AI sedang sibuk atau gambar tidak jelas.",
                "Periksa pangkal batang dari tanda Ganoderma (jamur putih, akar busuk berwarna coklat). Jika ada gejala, isolasi pohon dan konsultasi penyuluh. Hindari pelukaan batang saat panen.",
                "PERHATIAN", true);
            case "PELEPAH"-> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto secara otomatis saat ini.",
                "Layanan diagnosa AI sedang sibuk atau gambar tidak jelas.",
                "Pelepah menguning bisa menandakan defisiensi: Mg (menguning antar tulang daun), N (menguning seluruh daun), atau K (bercak oranye di pinggir). Aplikasikan pupuk sesuai gejala dan dosis standar PPKS.",
                "PERHATIAN", true);
            default       -> new VisualDiagnosaResult(
                "Tidak dapat menganalisa foto.",
                "Foto tidak teridentifikasi.",
                "Coba ambil foto lebih jelas dengan pencahayaan cukup.",
                "NORMAL", true);
        };
    }
}
