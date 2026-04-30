package com.sawitku.service;

import com.sawitku.dto.response.DiagnosaResponse;
import com.sawitku.entity.*;
import com.sawitku.exception.BusinessException;
import com.sawitku.exception.ResourceNotFoundException;
import com.sawitku.repository.DiagnosaRepository;
import com.sawitku.repository.LahanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DiagnosaService {

    private static final long MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB

    private final DiagnosaRepository diagnosaRepository;
    private final LahanRepository lahanRepository;
    private final ClaudeService claudeService;
    private final SubscriptionService subscriptionService;

    @Transactional
    public DiagnosaResponse analyze(Long userId, Long lahanId, MultipartFile image, String jenisStr) {
        // Validasi
        if (image == null || image.isEmpty())
            throw new BusinessException("Foto wajib diupload", "IMAGE_REQUIRED");
        if (image.getSize() > MAX_IMAGE_SIZE)
            throw new BusinessException("Ukuran foto maksimal 5MB", "IMAGE_TOO_LARGE");

        JenisDiagnosa jenis;
        try {
            jenis = JenisDiagnosa.valueOf(jenisStr.toUpperCase());
        } catch (Exception e) {
            throw new BusinessException("Jenis harus BUAH, BATANG, atau PELEPAH", "INVALID_JENIS");
        }

        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        // Cek limit subscription
        subscriptionService.checkLimitDiagnosaAI(userId);

        // Encode ke base64
        String imageBase64;
        try {
            imageBase64 = Base64.getEncoder().encodeToString(image.getBytes());
        } catch (Exception e) {
            throw new BusinessException("Gagal membaca file foto", "IMAGE_READ_ERROR");
        }

        // Panggil Claude Vision
        var result = claudeService.analyzeImage(imageBase64, jenis.name(), lahan);

        // Simpan ke DB
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

        // Increment counter hanya kalau bukan fallback
        if (!result.isFallback()) {
            subscriptionService.incrementDiagnosaCount(userId);
        }

        return toResponse(diagnosa, true);
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
