package com.sawitku.service;

import com.sawitku.dto.response.AiTelemetryResponse;
import com.sawitku.repository.AiUsageRepository;
import com.sawitku.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiTelemetryService {

    private final AiUsageRepository aiUsageRepo;
    private final UserRepository userRepo;

    public AiTelemetryResponse getCurrentTelemetry() {
        String period = currentPeriodJakarta();
        int total = aiUsageRepo.sumTotalCostByPeriod(period);
        long users = aiUsageRepo.countActiveUsersByPeriod(period);

        List<AiTelemetryResponse.TopSpender> topSpenders = aiUsageRepo
                .findTopSpendersByPeriod(period, PageRequest.of(0, 10))
                .stream()
                .map(r -> {
                    Long uid = ((Number) r[0]).longValue();
                    int cost = ((Number) r[1]).intValue();
                    String email = userRepo.findById(uid)
                            .map(u -> u.getEmail())
                            .orElse("(deleted)");
                    return AiTelemetryResponse.TopSpender.builder()
                            .userId(uid).userEmail(email).costCents(cost).build();
                })
                .toList();

        List<AiTelemetryResponse.ModelStat> modelBreakdown = aiUsageRepo
                .findModelBreakdownByPeriod(period)
                .stream()
                .map(r -> AiTelemetryResponse.ModelStat.builder()
                        .model((String) r[0])
                        .callCount(((Number) r[1]).longValue())
                        .totalCostCents(((Number) r[2]).intValue())
                        .build())
                .toList();

        return AiTelemetryResponse.builder()
                .period(period)
                .totalCostCents(total)
                .activeUsers(users)
                .topSpenders(topSpenders)
                .modelBreakdown(modelBreakdown)
                .build();
    }

    private String currentPeriodJakarta() {
        return LocalDate.now(ZoneId.of("Asia/Jakarta"))
                .format(DateTimeFormatter.ofPattern("yyyy-MM"));
    }
}
