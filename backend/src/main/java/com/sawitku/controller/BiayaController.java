package com.sawitku.controller;

import com.sawitku.dto.request.BiayaRequest;
import com.sawitku.dto.response.ApiResponse;
import com.sawitku.dto.response.BiayaResponse;
import com.sawitku.entity.User;
import com.sawitku.service.BiayaService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/lahan/{lahanId}/biaya")
@RequiredArgsConstructor
public class BiayaController {

    private final BiayaService biayaService;

    @PostMapping
    public ResponseEntity<ApiResponse<BiayaResponse>> create(@AuthenticationPrincipal User user,
                                                              @PathVariable Long lahanId,
                                                              @Valid @RequestBody BiayaRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ResponseUtil.ok(biayaService.createBiaya(user.getId(), lahanId, req),
                "Biaya berhasil dicatat").getBody());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BiayaResponse>>> list(@AuthenticationPrincipal User user,
                                                                  @PathVariable Long lahanId,
                                                                  @RequestParam(required = false) Integer tahun,
                                                                  @RequestParam(defaultValue = "50") int limit) {
        return ResponseUtil.ok(biayaService.getBiayaByLahan(user.getId(), lahanId, tahun, limit));
    }

    @PutMapping("/{biayaId}")
    public ResponseEntity<ApiResponse<BiayaResponse>> update(@AuthenticationPrincipal User user,
                                                              @PathVariable Long lahanId,
                                                              @PathVariable Long biayaId,
                                                              @Valid @RequestBody BiayaRequest req) {
        return ResponseUtil.ok(biayaService.updateBiaya(user.getId(), lahanId, biayaId, req),
            "Biaya berhasil diupdate");
    }

    @DeleteMapping("/{biayaId}")
    public ResponseEntity<ApiResponse<Void>> delete(@AuthenticationPrincipal User user,
                                                     @PathVariable Long lahanId,
                                                     @PathVariable Long biayaId) {
        biayaService.deleteBiaya(user.getId(), lahanId, biayaId);
        return ResponseUtil.ok(null, "Biaya berhasil dihapus");
    }
}
