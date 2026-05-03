package com.sawitku.controller;

import com.sawitku.dto.response.ApiResponse;
import com.sawitku.dto.response.LahanPhotoResponse;
import com.sawitku.entity.User;
import com.sawitku.service.LahanPhotoService;
import com.sawitku.util.ResponseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/lahan/{lahanId}/photos")
@RequiredArgsConstructor
public class LahanPhotoController {

    private final LahanPhotoService photoService;

    @PostMapping(consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<LahanPhotoResponse>> upload(
            @AuthenticationPrincipal User user,
            @PathVariable Long lahanId,
            @RequestParam("image") MultipartFile image,
            @RequestParam(value = "caption", required = false) String caption) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ResponseUtil.ok(
                        photoService.upload(user.getId(), lahanId, image, caption),
                        "Foto berhasil diupload").getBody());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<LahanPhotoResponse>>> list(
            @AuthenticationPrincipal User user,
            @PathVariable Long lahanId) {
        return ResponseUtil.ok(photoService.list(user.getId(), lahanId));
    }

    @DeleteMapping("/{photoId}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @AuthenticationPrincipal User user,
            @PathVariable Long lahanId,
            @PathVariable Long photoId) {
        photoService.delete(user.getId(), lahanId, photoId);
        return ResponseUtil.ok(null, "Foto berhasil dihapus");
    }
}
