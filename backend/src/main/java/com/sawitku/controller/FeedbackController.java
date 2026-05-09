package com.sawitku.controller;

import com.sawitku.dto.request.FeedbackRequest;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.UserRepository;
import com.sawitku.service.AuditService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/feedback")
@RequiredArgsConstructor
@Slf4j
public class FeedbackController {

    private final AuditService auditService;
    private final UserRepository userRepo;

    @Value("${app.feedback-email:admin@sawitku.id}")
    private String feedbackEmail;

    @PostMapping
    public ResponseEntity<?> submit(@Valid @RequestBody FeedbackRequest req,
                                    Authentication auth) {
        Long userId = null;
        String userEmail = req.getUserEmail();

        if (auth != null && auth.getName() != null) {
            userEmail = auth.getName();
            userId = userRepo.findByEmail(userEmail)
                .map(u -> u.getId())
                .orElse(null);
        }

        String detailPreview = req.getDetail().length() > 100
            ? req.getDetail().substring(0, 100) + "..."
            : req.getDetail();

        auditService.log(AuditAction.FEEDBACK_SUBMIT, userId, "Feedback", null,
            Map.of(
                "type", req.getType(),
                "subject", req.getSubject(),
                "detail_preview", detailPreview
            ));

        log.info("Feedback received from {}: [{}] {} - {}",
            userEmail, req.getType(), req.getSubject(), req.getDetail());

        return ResponseEntity.ok(
            Map.of("message", "Terima kasih atas feedback Anda. Tim kami akan meninjau."));
    }
}
