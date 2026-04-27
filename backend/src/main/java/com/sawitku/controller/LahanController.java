package com.sawitku.controller;

import com.sawitku.dto.request.LahanRequest;
import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.service.LahanService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/lahan")
@RequiredArgsConstructor
public class LahanController {

    private final LahanService lahanService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<LahanResponse>>> getMyLahan(@AuthenticationPrincipal User user) {
        return ResponseUtil.ok(lahanService.getMyLahan(user.getId()));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<LahanResponse>> create(@AuthenticationPrincipal User user,
                                                              @Valid @RequestBody LahanRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ResponseUtil.ok(lahanService.createLahan(user.getId(), req), "Lahan berhasil dibuat").getBody());
    }

    @GetMapping("/{lahanId}")
    public ResponseEntity<ApiResponse<LahanResponse>> getById(@AuthenticationPrincipal User user,
                                                               @PathVariable Long lahanId) {
        return ResponseUtil.ok(lahanService.getLahanById(user.getId(), lahanId));
    }

    @PutMapping("/{lahanId}")
    public ResponseEntity<ApiResponse<LahanResponse>> update(@AuthenticationPrincipal User user,
                                                              @PathVariable Long lahanId,
                                                              @Valid @RequestBody LahanRequest req) {
        return ResponseUtil.ok(lahanService.updateLahan(user.getId(), lahanId, req), "Lahan berhasil diupdate");
    }

    @DeleteMapping("/{lahanId}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal User user, @PathVariable Long lahanId) {
        lahanService.deleteLahan(user.getId(), lahanId);
        return ResponseEntity.noContent().build();
    }
}
