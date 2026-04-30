package com.sawitku.controller;

import com.sawitku.dto.response.ApiResponse;
import com.sawitku.dto.response.DiagnosaResponse;
import com.sawitku.entity.User;
import com.sawitku.service.DiagnosaService;
import com.sawitku.util.ResponseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;

@RestController
@RequestMapping("/api/lahan/{lahanId}/diagnosa")
@RequiredArgsConstructor
public class DiagnosaController {

    private final DiagnosaService diagnosaService;

    @PostMapping(value = "/visual", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<DiagnosaResponse>> analyze(@AuthenticationPrincipal User user,
                                                                   @PathVariable Long lahanId,
                                                                   @RequestParam("image") MultipartFile image,
                                                                   @RequestParam("jenis") String jenis) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ResponseUtil.ok(diagnosaService.analyze(user.getId(), lahanId, image, jenis),
                "Diagnosa berhasil").getBody());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<DiagnosaResponse>>> history(@AuthenticationPrincipal User user,
                                                                        @PathVariable Long lahanId,
                                                                        @RequestParam(defaultValue = "20") int limit) {
        return ResponseUtil.ok(diagnosaService.getHistory(user.getId(), lahanId, limit));
    }

    @GetMapping("/{diagnosaId}")
    public ResponseEntity<ApiResponse<DiagnosaResponse>> detail(@AuthenticationPrincipal User user,
                                                                  @PathVariable Long lahanId,
                                                                  @PathVariable Long diagnosaId) {
        return ResponseUtil.ok(diagnosaService.getDetail(user.getId(), lahanId, diagnosaId));
    }

    @DeleteMapping("/{diagnosaId}")
    public ResponseEntity<ApiResponse<Void>> delete(@AuthenticationPrincipal User user,
                                                     @PathVariable Long lahanId,
                                                     @PathVariable Long diagnosaId) {
        diagnosaService.delete(user.getId(), lahanId, diagnosaId);
        return ResponseUtil.ok(null, "Diagnosa berhasil dihapus");
    }
}
