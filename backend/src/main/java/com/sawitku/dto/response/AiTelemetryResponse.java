package com.sawitku.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class AiTelemetryResponse {

    private String period;
    private int totalCostCents;
    private long activeUsers;
    private List<TopSpender> topSpenders;
    private List<ModelStat> modelBreakdown;

    @Data
    @Builder
    public static class TopSpender {
        private Long userId;
        private String userEmail;
        private int costCents;
    }

    @Data
    @Builder
    public static class ModelStat {
        private String model;
        private long callCount;
        private int totalCostCents;
    }
}
