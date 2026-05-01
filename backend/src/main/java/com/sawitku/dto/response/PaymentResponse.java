package com.sawitku.dto.response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class PaymentResponse {
    private Long id;
    private String orderId;
    private String targetPaket;
    private Integer durationMonths;
    private BigDecimal grossAmount;
    private String status;
    private String paymentMethod;
    private String snapToken;
    private String snapUrl;
    private LocalDateTime paidAt;
    private LocalDateTime createdAt;
}
