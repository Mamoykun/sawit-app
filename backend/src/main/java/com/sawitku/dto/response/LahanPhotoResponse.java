package com.sawitku.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class LahanPhotoResponse {
    private Long id;
    private Long lahanId;
    private String imageUrl;
    private String caption;
    private LocalDateTime takenAt;
    private String bulan;
    private Integer tahun;
    private Integer bulanAngka;
}
