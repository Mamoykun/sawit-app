package com.sawitku.controller;

import com.sawitku.dto.request.PanenRequest;
import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.service.PanenService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/lahan/{lahanId}/panen")
@RequiredArgsConstructor
public class PanenController {

    private final PanenService panenService;

    @PostMapping
    public ResponseEntity<ApiResponse<PanenResponse>> input(@AuthenticationPrincipal User user,
                                                             @PathVariable Long lahanId,
                                                             @Valid @RequestBody PanenRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ResponseUtil.ok(panenService.inputPanen(user.getId(), lahanId, req), "Panen berhasil dicatat").getBody());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<PanenResponse>>> getRiwayat(@AuthenticationPrincipal User user,
                                                                         @PathVariable Long lahanId,
                                                                         @RequestParam(defaultValue = "7") int limit) {
        return ResponseUtil.ok(panenService.getRiwayat(user.getId(), lahanId, limit));
    }

    @GetMapping("/{panenId}")
    public ResponseEntity<ApiResponse<PanenResponse>> getDetail(@AuthenticationPrincipal User user,
                                                                  @PathVariable Long lahanId,
                                                                  @PathVariable Long panenId) {
        return ResponseUtil.ok(panenService.getPanenDetail(user.getId(), lahanId, panenId));
    }

    @GetMapping("/{panenId}/analisa")
    public ResponseEntity<ApiResponse<AnalisaResponse>> getAnalisa(@AuthenticationPrincipal User user,
                                                                     @PathVariable Long lahanId,
                                                                     @PathVariable Long panenId) {
        return ResponseUtil.ok(panenService.getAnalisaByPanen(user.getId(), lahanId, panenId));
    }
}
