package com.sawitku.dto.response;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AnalisaResponse {
    private Long id;
    private String status; // DONE, PROCESSING, FAILED
    private List<PenyebabItem> penyebab;
    private String ringkasan;
    private String prioritasTindakan;
    private LocalDateTime createdAt;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class PenyebabItem {
        private String icon;
        private String title;
        private String detail;
        private String severity;
        private String estimasiDampak;
    }
}
