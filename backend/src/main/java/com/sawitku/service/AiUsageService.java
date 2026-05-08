package com.sawitku.service;

import com.sawitku.entity.AiUsage;
import com.sawitku.entity.PaketSubscription;
import com.sawitku.repository.AiUsageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiUsageService {

    private final AiUsageRepository aiUsageRepository;
    private final SubscriptionService subscriptionService;

    // ─── Pricing constants (USD cents per 1M tokens) ─────────────────────────
    // Source: https://www.anthropic.com/pricing (accessed 2025-05)
    // Haiku  → input $0.25/M = 25 cents/M,  output $1.25/M = 125 cents/M
    // Sonnet → input $3.00/M = 300 cents/M, output $15.00/M = 1500 cents/M
    private static final int HAIKU_INPUT_CENTS_PER_M  =   25;
    private static final int HAIKU_OUTPUT_CENTS_PER_M =  125;
    private static final int SONNET_INPUT_CENTS_PER_M =  300;
    private static final int SONNET_OUTPUT_CENTS_PER_M = 1500;

    // ─── Monthly hard budget caps per paket (USD cents) ──────────────────────
    // GRATIS  → ~$0.10 (~20 Haiku calls)
    // PETANI  → ~$1.50 (~300 Haiku calls or ~5 Sonnet calls)
    // PRO     → ~$10.00 (effectively unlimited for normal usage)
    private static final int CAP_GRATIS = 10;
    private static final int CAP_PETANI = 150;
    private static final int CAP_PRO    = 1000;

    /** Internal stats snapshot (used by canSpend / internal callers). */
    public record AiUsageStats(int callCount, int totalTokens, int costCents, int capCents) {
        public int remainingCents() { return Math.max(0, capCents - costCents); }
        public double percentUsed() {
            if (capCents <= 0) return 0.0;
            return Math.min(100.0, (costCents * 100.0) / capCents);
        }
    }

    /**
     * Public DTO returned by the REST API.
     * All 7 fields are explicit so Jackson serializes them correctly.
     */
    public record AiUsageStatsDto(
            int callCount,
            int totalTokens,
            int costCents,
            int capCents,
            int remainingCents,
            int percentUsed,
            String paket) {}

    /** Builds an {@link AiUsageStatsDto} from an internal {@link AiUsageStats} and a paket name. */
    private AiUsageStatsDto toDto(AiUsageStats stats, String paketName) {
        return new AiUsageStatsDto(
                stats.callCount(),
                stats.totalTokens(),
                stats.costCents(),
                stats.capCents(),
                stats.remainingCents(),
                (int) stats.percentUsed(),
                paketName);
    }

    /** Record a completed Claude call and persist the cost. */
    public void record(Long userId, ClaudeService.ClaudeModel model, int inputTokens, int outputTokens) {
        try {
            int cost = computeCost(model, inputTokens, outputTokens);
            AiUsage usage = AiUsage.builder()
                .userId(userId)
                .period(currentPeriod())
                .model(model.name())
                .inputTokens(inputTokens)
                .outputTokens(outputTokens)
                .costUsdCents(cost)
                .build();
            aiUsageRepository.save(usage);
        } catch (Exception e) {
            log.warn("Failed to record AI usage for user {}: {}", userId, e.getMessage());
        }
    }

    /** Returns true when the user still has budget remaining for this month. */
    public boolean canSpend(Long userId) {
        try {
            String period = currentPeriod();
            int spent = aiUsageRepository.sumCostByUserPeriod(userId, period);
            int cap = capForUser(userId);
            return spent < cap;
        } catch (Exception e) {
            log.warn("canSpend check failed for user {}, allowing: {}", userId, e.getMessage());
            return true; // fail-open to avoid blocking users
        }
    }

    /** Returns usage stats DTO for the authenticated user in the current period. */
    public AiUsageStatsDto getStats(Long userId) {
        String period = currentPeriod();
        int callCount    = (int) aiUsageRepository.countByUserIdAndPeriod(userId, period);
        int totalTokens  = aiUsageRepository.sumTokensByUserPeriod(userId, period);
        int costCents    = aiUsageRepository.sumCostByUserPeriod(userId, period);
        int capCents     = capForUser(userId);
        AiUsageStats stats = new AiUsageStats(callCount, totalTokens, costCents, capCents);
        String paketName;
        try {
            paketName = subscriptionService.getPaket(userId).name();
        } catch (Exception e) {
            paketName = "GRATIS";
        }
        return toDto(stats, paketName);
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    /** Current billing period in YYYY-MM format, Asia/Jakarta timezone. */
    String currentPeriod() {
        return LocalDate.now(ZoneId.of("Asia/Jakarta"))
            .format(DateTimeFormatter.ofPattern("yyyy-MM"));
    }

    private int capForUser(Long userId) {
        try {
            PaketSubscription paket = subscriptionService.getPaket(userId);
            return switch (paket) {
                case GRATIS -> CAP_GRATIS;
                case PETANI -> CAP_PETANI;
                case PRO    -> CAP_PRO;
            };
        } catch (Exception e) {
            return CAP_GRATIS; // safe default
        }
    }

    private int computeCost(ClaudeService.ClaudeModel model, int inputTokens, int outputTokens) {
        return switch (model) {
            case HAIKU  -> (inputTokens  * HAIKU_INPUT_CENTS_PER_M  / 1_000_000)
                         + (outputTokens * HAIKU_OUTPUT_CENTS_PER_M / 1_000_000);
            case SONNET -> (inputTokens  * SONNET_INPUT_CENTS_PER_M  / 1_000_000)
                         + (outputTokens * SONNET_OUTPUT_CENTS_PER_M / 1_000_000);
        };
    }
}
