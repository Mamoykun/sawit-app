package com.sawitku.controller;

import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.service.LahanService;
import com.sawitku.util.ResponseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/beranda")
@RequiredArgsConstructor
public class BerandaController {

    private final LahanService lahanService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getBeranda(@AuthenticationPrincipal User user) {
        List<LahanResponse> lahans = lahanService.getMyLahan(user.getId());
        long normal = lahans.stream().filter(l -> l.getPanenTerakhir() != null && "NORMAL".equals(l.getStatusTerkini())).count();
        long bermasalah = lahans.stream().filter(l -> l.getPanenTerakhir() != null && !"NORMAL".equals(l.getStatusTerkini())).count();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("totalLahan", lahans.size());
        data.put("lahanNormal", normal);
        data.put("lahanBermasalah", bermasalah);
        data.put("lahan", lahans);
        return ResponseUtil.ok(data);
    }
}
