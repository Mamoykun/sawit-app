package com.sawitku.util;

import com.sawitku.exception.BusinessException;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/// Validates uploaded image bytes for diagnosa endpoint.
///
/// Defense layers:
///  1. Magic bytes (file signature) — rejects renamed files (e.g. .exe disguised as .jpg)
///  2. Min/max dimensions — rejects 1×1 pixel abuse and absurdly large images
///  3. SHA-256 hash — used by service layer with Redis to detect duplicate uploads
public final class ImageValidator {
    private ImageValidator() {}

    public static final long MAX_BYTES = 5L * 1024 * 1024;       // 5 MB
    public static final int MIN_DIMENSION = 200;                  // 200×200 minimum
    public static final int MAX_DIMENSION = 4096;                 // 4096×4096 maximum

    /// Validate that bytes represent a real JPEG or PNG image of acceptable dimensions.
    /// Throws BusinessException with user-readable Indonesian message on failure.
    public static void validate(byte[] bytes) {
        if (bytes == null || bytes.length == 0) {
            throw new BusinessException("Foto kosong", "IMAGE_EMPTY");
        }
        if (bytes.length > MAX_BYTES) {
            throw new BusinessException(
                "Ukuran foto melebihi 5MB. Mohon kompres foto terlebih dahulu.",
                "IMAGE_TOO_LARGE");
        }

        // Magic bytes check (first few bytes identify file format)
        if (!isJpeg(bytes) && !isPng(bytes)) {
            throw new BusinessException(
                "Format foto tidak didukung. Hanya JPEG dan PNG yang diterima.",
                "IMAGE_INVALID_FORMAT");
        }

        // Dimension check via ImageIO
        try {
            BufferedImage img = ImageIO.read(new ByteArrayInputStream(bytes));
            if (img == null) {
                throw new BusinessException(
                    "File foto tidak dapat dibaca atau rusak.",
                    "IMAGE_CORRUPT");
            }
            int w = img.getWidth();
            int h = img.getHeight();
            if (w < MIN_DIMENSION || h < MIN_DIMENSION) {
                throw new BusinessException(
                    "Resolusi foto terlalu kecil (minimal 200×200 piksel).",
                    "IMAGE_TOO_SMALL");
            }
            if (w > MAX_DIMENSION || h > MAX_DIMENSION) {
                throw new BusinessException(
                    "Resolusi foto terlalu besar (maksimal 4096×4096 piksel).",
                    "IMAGE_TOO_LARGE_DIMENSIONS");
            }
            // Reject extreme aspect ratios (10:1 or worse) — usually screenshots/banners, not real photos
            double ratio = (double) Math.max(w, h) / Math.min(w, h);
            if (ratio > 10.0) {
                throw new BusinessException(
                    "Rasio foto tidak wajar. Mohon foto langsung tanaman, bukan screenshot.",
                    "IMAGE_BAD_RATIO");
            }
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException(
                "Gagal memvalidasi foto. Coba foto lain.",
                "IMAGE_VALIDATION_ERROR");
        }
    }

    /// Compute SHA-256 hash of image bytes (hex string, 64 chars).
    /// Used by DiagnosaService for duplicate detection via Redis.
    public static String sha256Hex(byte[] bytes) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(bytes);
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    private static boolean isJpeg(byte[] b) {
        return b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF;
    }

    private static boolean isPng(byte[] b) {
        return b.length >= 8
            && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G'
            && b[4] == 0x0D && b[5] == 0x0A && b[6] == 0x1A && b[7] == 0x0A;
    }
}
