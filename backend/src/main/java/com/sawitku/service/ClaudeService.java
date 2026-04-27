package com.sawitku.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.dto.response.AnalisaResponse;
import com.sawitku.entity.*;
import com.sawitku.repository.AnalisaRepository;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class ClaudeService {

    private final AnalisaRepository analisaRepository;
    private final RedisTemplate<String, String> redisTemplate;
    private final SubscriptionService subscriptionService;
    private final ObjectMapper objectMapper;

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
            redisTemplate.opsForValue().set(cacheKey, "DONE", 7, TimeUnit.DAYS);
        } catch (Exception e) {
            log.error("Claude API error untuk panen {}: {}", panen.getId(), e.getMessage());
            saveFallbackAnalisa(panen, lahan);
            redisTemplate.opsForValue().set(cacheKey, "DONE", 7, TimeUnit.DAYS);
        }
    }

    private String buildPrompt(Panen panen, Lahan lahan) {
        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        return """
            Kamu adalah ahli agronomi perkebunan sawit Indonesia berpengalaman 20 tahun.

            Data kebun:
            - Nama lahan: %s
            - Luas: %s hektar
            - Usia pohon: %d tahun
            - Fase produksi: %s
            - Lokasi: %s

            Data panen %s %d:
            - Hasil aktual: %s ton
            - Target normal: %s - %s ton
            - Kekurangan: %s%% dari target

            Analisa penyebab mengapa panen di bawah target dan berikan rekomendasi spesifik.
            Balas HANYA dengan JSON valid (tanpa markdown/backtick):
            {"penyebab":[{"icon":"emoji","title":"judul singkat","detail":"penjelasan + rekomendasi 2-3 kalimat","severity":"high|medium|low","estimasi_dampak":"X-Y%% penurunan"}],"ringkasan":"ringkasan 1 kalimat","prioritas_tindakan":"tindakan paling penting minggu ini"}
            """.formatted(
                lahan.getNamaLahan(), lahan.getLuasHa(), lahan.getUsiaPohon(),
                target.fase(), lahan.getLokasi() != null ? lahan.getLokasi() : "Tidak diketahui",
                panen.getBulan(), panen.getTahun(),
                panen.getTonAktual(), panen.getTargetMin(), panen.getTargetMax(),
                panen.getPersenKurang()
            );
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
        if (persen > 8) list.add(item("🌿", "Defisiensi Kalium (K)", "Aplikasikan pupuk MOP 0.5–1 kg per pohon. Kalium meningkatkan bobot tandan dan kualitas minyak sawit.", "high", "8-15%"));
        if (persen > 15) list.add(item("💧", "Stres Kekeringan", "Pasang mulsa pelepah di piringan pohon radius 2 meter untuk menjaga kelembaban tanah di musim kering.", "high", "10-20%"));
        if (persen > 20) list.add(item("🐛", "Serangan Hama / Penyakit", "Periksa tanda ulat api, kumbang badak, atau gejala Ganoderma di pangkal batang pohon.", "medium", "5-15%"));
        if (list.isEmpty()) list.add(item("🌡️", "Faktor Musiman Normal", "Fluktuasi 1–8% masih dalam batas wajar akibat perubahan cuaca dan siklus alami tanaman sawit.", "low", "1-8%"));
        return list;
    }

    private AnalisaResponse.PenyebabItem item(String icon, String title, String detail, String severity, String dampak) {
        return AnalisaResponse.PenyebabItem.builder()
            .icon(icon).title(title).detail(detail).severity(severity).estimasiDampak(dampak).build();
    }
}
