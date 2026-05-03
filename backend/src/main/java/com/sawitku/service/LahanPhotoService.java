package com.sawitku.service;

import com.sawitku.dto.response.LahanPhotoResponse;
import com.sawitku.entity.LahanPhoto;
import com.sawitku.entity.Lahan;
import com.sawitku.exception.BusinessException;
import com.sawitku.exception.ResourceNotFoundException;
import com.sawitku.repository.LahanPhotoRepository;
import com.sawitku.repository.LahanRepository;
import com.sawitku.util.ImageValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Service for managing lahan progress photos.
 *
 * <p>Storage strategy: files are saved to local disk at
 * {@code {upload.dir}/photos/{lahanId}/{uuid}.jpg}.
 * The {@code upload.dir} property defaults to {@code uploads} (relative to
 * the working directory). The path is served as static resources via
 * {@code /photos/**} by {@code WebConfig}.
 *
 * <p>If you prefer cloud storage (S3, GCS), replace the
 * {@link #saveFile(Long, byte[], String)} helper with the cloud SDK call
 * and update {@link #buildImageUrl(Long, String)} accordingly.
 */
@Service
@RequiredArgsConstructor
public class LahanPhotoService {

    private final LahanPhotoRepository photoRepository;
    private final LahanRepository lahanRepository;

    @Value("${upload.dir:uploads}")
    private String uploadDir;

    @Value("${app.base-url:http://localhost:8080}")
    private String baseUrl;

    // ── Public API ────────────────────────────────────────────────────────────

    @Transactional
    public LahanPhotoResponse upload(Long userId, Long lahanId,
                                      MultipartFile file, String caption) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("Foto wajib diupload", "IMAGE_REQUIRED");
        }

        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw new BusinessException("Gagal membaca file foto", "IMAGE_READ_ERROR");
        }

        // Reuse existing validator (magic bytes + size)
        ImageValidator.validate(bytes);

        String filename = UUID.randomUUID() + ".jpg";
        String storedPath = saveFile(lahanId, bytes, filename);
        String imageUrl = buildImageUrl(lahanId, filename);

        LocalDateTime now = LocalDateTime.now();
        // Derive bulan/tahun from current date for grouping
        String[] months = {
            "Januari", "Februari", "Maret", "April", "Mei", "Juni",
            "Juli", "Agustus", "September", "Oktober", "November", "Desember"
        };
        String bulan = months[now.getMonthValue() - 1];
        int tahun = now.getYear();
        int bulanAngka = now.getMonthValue();

        LahanPhoto photo = LahanPhoto.builder()
                .lahan(lahan)
                .imageUrl(imageUrl)
                .caption(caption)
                .takenAt(now)
                .createdAt(now)
                .bulan(bulan)
                .tahun(tahun)
                .bulanAngka(bulanAngka)
                .build();

        photoRepository.save(photo);
        return toResponse(photo);
    }

    public List<LahanPhotoResponse> list(Long userId, Long lahanId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        return photoRepository.findByLahanIdOrderByTakenAtDesc(lahanId)
                .stream().map(this::toResponse).toList();
    }

    @Transactional
    public void delete(Long userId, Long lahanId, Long photoId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        LahanPhoto photo = photoRepository.findByIdAndLahanId(photoId, lahanId)
                .orElseThrow(() -> new ResourceNotFoundException("Foto tidak ditemukan"));
        photoRepository.delete(photo);
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    /**
     * Saves bytes to {@code uploads/photos/{lahanId}/{filename}}.
     * Returns the relative path for logging.
     */
    private String saveFile(Long lahanId, byte[] bytes, String filename) {
        try {
            Path dir = Paths.get(uploadDir, "photos", lahanId.toString());
            Files.createDirectories(dir);
            Path dest = dir.resolve(filename);
            Files.write(dest, bytes);
            return dest.toString();
        } catch (IOException e) {
            throw new BusinessException("Gagal menyimpan foto: " + e.getMessage(), "FILE_SAVE_ERROR");
        }
    }

    /**
     * Builds a publicly accessible URL for the photo.
     * Served by Spring's static resource handler at /photos/**.
     */
    private String buildImageUrl(Long lahanId, String filename) {
        return baseUrl + "/photos/" + lahanId + "/" + filename;
    }

    private LahanPhotoResponse toResponse(LahanPhoto p) {
        return LahanPhotoResponse.builder()
                .id(p.getId())
                .lahanId(p.getLahan().getId())
                .imageUrl(p.getImageUrl())
                .caption(p.getCaption())
                .takenAt(p.getTakenAt())
                .bulan(p.getBulan())
                .tahun(p.getTahun())
                .bulanAngka(p.getBulanAngka())
                .build();
    }
}
