package com.sawitku.util;

import com.sawitku.dto.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import java.time.LocalDateTime;

public class ResponseUtil {
    public static <T> ResponseEntity<ApiResponse<T>> ok(T data, String message) {
        return ResponseEntity.ok(ApiResponse.<T>builder()
            .success(true).message(message).data(data)
            .timestamp(LocalDateTime.now()).build());
    }

    public static <T> ResponseEntity<ApiResponse<T>> ok(T data) {
        return ok(data, "Berhasil");
    }
}
