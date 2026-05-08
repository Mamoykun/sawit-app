package com.sawitku.repository;

import com.sawitku.entity.AiUsage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface AiUsageRepository extends JpaRepository<AiUsage, Long> {

    @Query("SELECT COALESCE(SUM(u.costUsdCents), 0) FROM AiUsage u WHERE u.userId = :userId AND u.period = :period")
    int sumCostByUserPeriod(@Param("userId") Long userId, @Param("period") String period);

    @Query("SELECT COALESCE(SUM(u.inputTokens + u.outputTokens), 0) FROM AiUsage u WHERE u.userId = :userId AND u.period = :period")
    int sumTokensByUserPeriod(@Param("userId") Long userId, @Param("period") String period);

    long countByUserIdAndPeriod(Long userId, String period);

    // ─── Admin telemetry aggregations ────────────────────────────────────────

    @Query("SELECT COALESCE(SUM(u.costUsdCents), 0) FROM AiUsage u WHERE u.period = :period")
    int sumTotalCostByPeriod(@Param("period") String period);

    @Query("SELECT COUNT(DISTINCT u.userId) FROM AiUsage u WHERE u.period = :period")
    long countActiveUsersByPeriod(@Param("period") String period);

    @Query("SELECT u.userId, SUM(u.costUsdCents) AS cost FROM AiUsage u WHERE u.period = :period GROUP BY u.userId ORDER BY cost DESC")
    List<Object[]> findTopSpendersByPeriod(@Param("period") String period, Pageable pageable);

    @Query("SELECT u.model, COUNT(u), SUM(u.costUsdCents) FROM AiUsage u WHERE u.period = :period GROUP BY u.model")
    List<Object[]> findModelBreakdownByPeriod(@Param("period") String period);
}
