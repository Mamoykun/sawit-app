package com.sawitku.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class DiagnosaResponse {
    private Long id;
    private Long lahanId;
    private String jenis;
    private String kondisi;
    private String penyebab;
    private String rekomendasi;
    private String severity;
    private Boolean isFallback;
    private String imageBase64;
    private LocalDateTime createdAt;
}
