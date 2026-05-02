package com.sawitku.service;

import com.sawitku.dto.response.DiagnosaResponse;
import com.sawitku.entity.*;
import com.sawitku.exception.BusinessException;
import com.sawitku.exception.ResourceNotFoundException;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.DiagnosaRepository;
import com.sawitku.repository.LahanRepository;
import com.sawitku.util.ImageValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class DiagnosaService {

    /// Sliding window: max 5 diagnosa attempts per hour per user.
    /// Prevents spam abuse beyond the monthly subscription quota.
    private static final int RATE_LIMIT_PER_HOUR = 5;
    /// Image dedup window: same SHA-256 hash within 24h for the same user is rejected.
    private static final int DEDUP_WINDOW_HOURS = 24;

    private final DiagnosaRepository diagnosaRepository;
    private final LahanRepository lahanRepository;
    private final ClaudeService claudeService;
    private final SubscriptionService subscriptionService;
    private final AuditService auditService;

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private RedisTemplate<String, String> redisTemplate;

    @Transactional
    public DiagnosaResponse analyze(Long userId, Long lahanId, MultipartFile image, String jenisStr) {
        // Layer 1: Basic checks
        if (image == null || image.isEmpty())
            throw new BusinessException("Foto wajib diupload", "IMAGE_REQUIRED");

        JenisDiagnosa jenis;
        try {
            jenis = JenisDiagnosa.valueOf(jenisStr.toUpperCase());
        } catch (Exception e) {
            throw new BusinessException("Jenis harus BUAH, BATANG, atau PELEPAH", "INVALID_JENIS");
        }

        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        // Read bytes once for validation + hashing + encoding
        byte[] imageBytes;
        try {
            imageBytes = image.getBytes();
        } catch (Exception e) {
            throw new BusinessException("Gagal membaca file foto", "IMAGE_READ_ERROR");
        }

        // Layer 2: Magic bytes + dimensions + aspect ratio validation
        ImageValidator.validate(imageBytes);

        // Layer 3: Image hash dedup (Redis, 24h window per user)
        String hash = ImageValidator.sha256Hex(imageBytes);
        checkDuplicateUpload(userId, hash);

        // Layer 4: Sliding window rate limit (5 attempts/hour per user)
        checkRateLimit(userId);

        // Layer 5: Subscription monthly quota check
        subscriptionService.checkLimitDiagnosaAI(userId);

        // Encode for Claude Vision API
        String imageBase64 = Base64.getEncoder().encodeToString(imageBytes);

        // Send to Claude Vision
        var result = claudeService.analyzeImage(imageBase64, jenis.name(), lahan);

        // Mark this attempt in rate limit (regardless of result)
        recordRateLimitAttempt(userId);

        // Cache hash to prevent duplicate within 24h
        cacheImageHash(userId, hash);

        // Detect non-sawit photo from Claude response — don't save image, don't count quota.
        boolean isNotSawit = isNotSawitPhoto(result);
        if (isNotSawit) {
            // Return error directly without saving (saves DB space)
            throw new BusinessException(
                "Foto yang Anda upload terdeteksi BUKAN tanaman sawit. "
                    + "Mohon foto langsung buah, batang, atau pelepah sawit. "
                    + "Diagnosa ini tidak mengurangi kuota Anda.",
                "PHOTO_NOT_SAWIT");
        }

        // Save to DB
        Diagnosa diagnosa = Diagnosa.builder()
            .lahan(lahan)
            .jenis(jenis)
            .imageBase64(imageBase64)
            .kondisi(result.kondisi())
            .penyebab(result.penyebab())
            .rekomendasi(result.rekomendasi())
            .severity(SeverityDiagnosa.valueOf(result.severity()))
            .isFallback(result.isFallback())
            .createdAt(LocalDateTime.now())
            .build();
        diagnosaRepository.save(diagnosa);

        try { auditService.log(AuditAction.DIAGNOSA_CREATE, userId, "Diagnosa", diagnosa.getId(),
                Map.of("lahanId", lahanId, "jenis", jenis.name(), "isFallback", result.isFallback())); }
        catch (Exception ignored) {}

        // Increment counter hanya kalau bukan fallback (Claude error)
        if (!result.isFallback()) {
            subscriptionService.incrementDiagnosaCount(userId);
        }

        return toResponse(diagnosa, true);
    }

    /// Heuristic: detect if Claude flagged the photo as non-sawit.
    /// Updated prompt instructs Claude to say "BUKAN_SAWIT" in kondisi field.
    private boolean isNotSawitPhoto(ClaudeService.VisualDiagnosaResult r) {
        if (r.isFallback()) return false; // fallback = AI error, not photo issue
        String k = (r.kondisi() != null ? r.kondisi() : "").toUpperCase();
        return k.contains("BUKAN_SAWIT") || k.contains("BUKAN SAWIT");
    }

    // ─── REDIS-BACKED ABUSE PROTECTION ────────────────────────────────────────

    private void checkDuplicateUpload(Long userId, String hash) {
        if (redisTemplate == null) return; // dev mode without redis
        String key = "diag_hash:" + userId + ":" + hash;
        if (redisTemplate.hasKey(key)) {
            throw new BusinessException(
                "Anda baru saja menganalisa foto yang sama. "
                    + "Tunggu " + DEDUP_WINDOW_HOURS + " jam atau coba foto lain.",
                "IMAGE_DUPLICATE");
        }
    }

    private void cacheImageHash(Long userId, String hash) {
        if (redisTemplate == null) return;
        String key = "diag_hash:" + userId + ":" + hash;
        redisTemplate.opsForValue().set(key, "1", DEDUP_WINDOW_HOURS, TimeUnit.HOURS);
    }

    private void checkRateLimit(Long userId) {
        if (redisTemplate == null) return;
        String key = "diag_rate:" + userId;
        String val = redisTemplate.opsForValue().get(key);
        int count = val != null ? Integer.parseInt(val) : 0;
        if (count >= RATE_LIMIT_PER_HOUR) {
            throw new BusinessException(
                "Terlalu banyak diagnosa dalam 1 jam terakhir (maks " + RATE_LIMIT_PER_HOUR
                    + "). Coba lagi nanti.",
                "RATE_LIMIT_DIAGNOSA");
        }
    }

    private void recordRateLimitAttempt(Long userId) {
        if (redisTemplate == null) return;
        String key = "diag_rate:" + userId;
        Long newCount = redisTemplate.opsForValue().increment(key);
        if (newCount != null && newCount == 1L) {
            redisTemplate.expire(key, 1, TimeUnit.HOURS);
        }
    }

    public List<DiagnosaResponse> getHistory(Long userId, Long lahanId, int limit) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        return diagnosaRepository.findByLahanIdOrderByCreatedAtDesc(lahanId, PageRequest.of(0, limit))
            .stream().map(d -> toResponse(d, false)).toList();
    }

    public DiagnosaResponse getDetail(Long userId, Long lahanId, Long diagnosaId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Diagnosa d = diagnosaRepository.findByIdAndLahanId(diagnosaId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Diagnosa tidak ditemukan"));
        return toResponse(d, true);
    }

    @Transactional
    public void delete(Long userId, Long lahanId, Long diagnosaId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Diagnosa d = diagnosaRepository.findByIdAndLahanId(diagnosaId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Diagnosa tidak ditemukan"));
        diagnosaRepository.delete(d);
        try { auditService.log(AuditAction.DIAGNOSA_DELETE, userId, "Diagnosa", diagnosaId,
                Map.of("lahanId", lahanId)); }
        catch (Exception ignored) {}
    }

    private DiagnosaResponse toResponse(Diagnosa d, boolean includeImage) {
        return DiagnosaResponse.builder()
            .id(d.getId())
            .lahanId(d.getLahan().getId())
            .jenis(d.getJenis().name())
            .kondisi(d.getKondisi())
            .penyebab(d.getPenyebab())
            .rekomendasi(d.getRekomendasi())
            .severity(d.getSeverity().name())
            .isFallback(d.getIsFallback())
            .imageBase64(includeImage ? d.getImageBase64() : null)
            .createdAt(d.getCreatedAt())
            .build();
    }
}
