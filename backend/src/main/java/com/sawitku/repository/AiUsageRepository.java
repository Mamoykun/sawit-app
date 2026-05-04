package com.sawitku.repository;

import com.sawitku.entity.AiUsage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AiUsageRepository extends JpaRepository<AiUsage, Long> {

    @Query("SELECT COALESCE(SUM(u.costUsdCents), 0) FROM AiUsage u WHERE u.userId = :userId AND u.period = :period")
    int sumCostByUserPeriod(@Param("userId") Long userId, @Param("period") String period);

    @Query("SELECT COALESCE(SUM(u.inputTokens + u.outputTokens), 0) FROM AiUsage u WHERE u.userId = :userId AND u.period = :period")
    int sumTokensByUserPeriod(@Param("userId") Long userId, @Param("period") String period);

    long countByUserIdAndPeriod(Long userId, String period);
}
