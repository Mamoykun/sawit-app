package com.sawitku.service;

import com.sawitku.entity.Analisa;
import com.sawitku.repository.AnalisaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class AnalisaUpgradeJob {

    private final AnalisaRepository analisaRepo;
    private final ClaudeService claudeService;
    private final AiUsageService aiUsageService;

    /** Run at 02:00 Asia/Jakarta every day. Upgrade up to 50 local fallbacks to AI. */
    @Scheduled(cron = "0 0 2 * * *", zone = "Asia/Jakarta")
    public void upgradeLocalFallbacks() {
        var fallbacks = analisaRepo.findLocalFallbacks(PageRequest.of(0, 50));
        log.info("AnalisaUpgradeJob: {} local fallbacks queued for upgrade", fallbacks.size());

        int upgraded = 0, skipped = 0, failed = 0;
        for (Analisa a : fallbacks) {
            try {
                Long userId = a.getLahan().getUser().getId();
                if (!aiUsageService.canSpend(userId)) { skipped++; continue; }
                claudeService.analyzePanenSync(a.getPanen(), a.getLahan());
                upgraded++;
            } catch (Exception e) {
                log.warn("Failed to upgrade analisa id={}: {}", a.getId(), e.getMessage());
                failed++;
            }
        }
        log.info("AnalisaUpgradeJob done: upgraded={} skipped={} failed={}", upgraded, skipped, failed);
    }
}
