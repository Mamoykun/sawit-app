package com.sawitku.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.dto.request.PanenRequest;
import com.sawitku.dto.response.*;
import com.sawitku.entity.*;
import com.sawitku.exception.*;
import com.sawitku.repository.*;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PanenService {

    private final PanenRepository panenRepository;
    private final LahanRepository lahanRepository;
    private final AnalisaRepository analisaRepository;
    private final ClaudeService claudeService;
    private final ObjectMapper objectMapper;

    @Transactional
    public PanenResponse inputPanen(Long userId, Long lahanId, PanenRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        if (panenRepository.existsByLahanIdAndTahunAndBulanAngka(lahanId, req.getTahun(), req.getBulanAngka()))
            throw new BusinessException("Data panen " + req.getBulan() + " " + req.getTahun() + " sudah ada", "DUPLICATE_PANEN");

        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        BigDecimal persen = AnalisaCalculator.hitungPersenKurang(req.getTonAktual(), target.mid());
        StatusPanen status = AnalisaCalculator.getStatus(req.getTonAktual(), target.min(), target.mid());

        Panen panen = Panen.builder()
            .lahan(lahan).bulan(req.getBulan()).tahun(req.getTahun()).bulanAngka(req.getBulanAngka())
            .tonAktual(req.getTonAktual()).targetMin(target.min()).targetMax(target.max()).targetMid(target.mid())
            .statusPanen(status).persenKurang(persen)
            .hargaPerTon(req.getHargaPerTon() != null ? req.getHargaPerTon() : BigDecimal.valueOf(2400000))
            .catatan(req.getCatatan()).createdAt(LocalDateTime.now()).build();
        panenRepository.save(panen);

        claudeService.analyzePanen(panen, lahan);

        return toResponse(panen, lahan.getNamaLahan(), null);
    }

    public List<PanenResponse> getRiwayat(Long userId, Long lahanId, int limit) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        return panenRepository.findByLahanIdOrderByTahunDescBulanAngkaDesc(lahanId, PageRequest.of(0, limit))
            .stream().map(p -> toResponse(p, null, getAnalisa(p))).toList();
    }

    public PanenResponse getPanenDetail(Long userId, Long lahanId, Long panenId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Panen panen = panenRepository.findByIdAndLahanId(panenId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Data panen tidak ditemukan"));
        return toResponse(panen, lahan.getNamaLahan(), getAnalisa(panen));
    }

    public AnalisaResponse getAnalisaByPanen(Long userId, Long lahanId, Long panenId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Panen panen = panenRepository.findByIdAndLahanId(panenId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Data panen tidak ditemukan"));
        AnalisaResponse analisa = getAnalisa(panen);
        if (analisa == null) return AnalisaResponse.builder().status("PROCESSING").build();
        return analisa;
    }

    private AnalisaResponse getAnalisa(Panen panen) {
        return analisaRepository.findByPanenId(panen.getId()).map(a -> {
            try {
                List<AnalisaResponse.PenyebabItem> items = objectMapper.readValue(
                    a.getPenyebabJson(), new TypeReference<>() {});
                return AnalisaResponse.builder()
                    .id(a.getId()).status("DONE").penyebab(items)
                    .ringkasan(null).prioritasTindakan(a.getRekomendasi())
                    .createdAt(a.getCreatedAt()).build();
            } catch (Exception e) { return null; }
        }).orElse(null);
    }

    private PanenResponse toResponse(Panen p, String namaLahan, AnalisaResponse analisa) {
        return PanenResponse.builder()
            .id(p.getId()).lahanId(p.getLahan().getId()).namaLahan(namaLahan)
            .bulan(p.getBulan()).tahun(p.getTahun()).bulanAngka(p.getBulanAngka())
            .tonAktual(p.getTonAktual()).targetMin(p.getTargetMin())
            .targetMax(p.getTargetMax()).targetMid(p.getTargetMid())
            .statusPanen(p.getStatusPanen().name()).persenKurang(p.getPersenKurang())
            .hargaPerTon(p.getHargaPerTon())
            .nilaiEstimasi(p.getTonAktual().multiply(p.getHargaPerTon()))
            .catatan(p.getCatatan()).createdAt(p.getCreatedAt()).analisa(analisa).build();
    }
}
