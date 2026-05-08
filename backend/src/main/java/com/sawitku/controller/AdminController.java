package com.sawitku.controller;

import com.sawitku.service.AiTelemetryService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AiTelemetryService telemetryService;

    @Value("${app.admin-emails:}")
    private String adminEmailsCsv;

    @GetMapping("/ai-telemetry")
    public ResponseEntity<?> getAiTelemetry(Authentication auth) {
        if (!isAdmin(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "admin only"));
        }
        return ResponseEntity.ok(Map.of("data", telemetryService.getCurrentTelemetry()));
    }

    private boolean isAdmin(Authentication auth) {
        if (auth == null || auth.getName() == null) return false;
        String email = auth.getName().toLowerCase();
        return Arrays.stream(adminEmailsCsv.split(","))
                .map(String::trim)
                .map(String::toLowerCase)
                .anyMatch(e -> !e.isEmpty() && e.equals(email));
    }
}
