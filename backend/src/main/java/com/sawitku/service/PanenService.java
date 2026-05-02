package com.sawitku.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.dto.request.PanenRequest;
import com.sawitku.dto.response.*;
import com.sawitku.entity.*;
import com.sawitku.exception.*;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.*;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PanenService {

    private final PanenRepository panenRepository;
    private final LahanRepository lahanRepository;
    private final AnalisaRepository analisaRepository;
    private final ClaudeService claudeService;
    private final ObjectMapper objectMapper;
    private final AuditService auditService;

    @Transactional
    public PanenResponse inputPanen(Long userId, Long lahanId, PanenRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        BigDecimal persen = AnalisaCalculator.hitungPersenKurang(req.getTonAktual(), target.mid());
        StatusPanen status = AnalisaCalculator.getStatus(req.getTonAktual(), target.min(), target.mid());

        Panen panen = Panen.builder()
            .lahan(lahan).bulan(req.getBulan()).tahun(req.getTahun()).bulanAngka(req.getBulanAngka())
            .tanggal(req.getTanggal())
            .tonAktual(req.getTonAktual()).targetMin(target.min()).targetMax(target.max()).targetMid(target.mid())
            .statusPanen(status).persenKurang(persen)
            .hargaPerTon(req.getHargaPerTon() != null ? req.getHargaPerTon() : BigDecimal.valueOf(2400000))
            .catatan(req.getCatatan()).createdAt(LocalDateTime.now()).build();
        panenRepository.save(panen);

        try { auditService.log(AuditAction.PANEN_CREATE, userId, "Panen", panen.getId(),
                Map.of("lahanId", lahanId)); }
        catch (Exception ignored) {}

        // Run after commit so the panen row is visible before the async FK write
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { claudeService.analyzePanen(panen, lahan); }
        });

        return toResponse(panen, lahan, null);
    }

    public List<PanenResponse> getRiwayat(Long userId, Long lahanId, int limit) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        return panenRepository.findByLahanIdOrderByTahunDescBulanAngkaDesc(lahanId, PageRequest.of(0, limit))
            .stream().map(p -> toResponse(p, lahan, getAnalisa(p))).toList();
    }

    public PanenResponse getPanenDetail(Long userId, Long lahanId, Long panenId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Panen panen = panenRepository.findByIdAndLahanId(panenId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Data panen tidak ditemukan"));
        return toResponse(panen, lahan, getAnalisa(panen));
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

    @Transactional
    public void deletePanen(Long userId, Long lahanId, Long panenId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Panen panen = panenRepository.findByIdAndLahanId(panenId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Data panen tidak ditemukan"));
        // Explicitly delete analisa first to avoid FK constraint issues
        // (DB has ON DELETE CASCADE but JPA cascade can be unreliable in some session states)
        analisaRepository.findByPanenId(panenId).ifPresent(analisaRepository::delete);
        analisaRepository.flush();
        panenRepository.delete(panen);
        try { auditService.log(AuditAction.PANEN_DELETE, userId, "Panen", panenId,
                Map.of("lahanId", lahanId)); }
        catch (Exception ignored) {}
    }

    @Transactional
    public PanenResponse updatePanen(Long userId, Long lahanId, Long panenId, PanenRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Panen panen = panenRepository.findByIdAndLahanId(panenId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Data panen tidak ditemukan"));

        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        BigDecimal persen = AnalisaCalculator.hitungPersenKurang(req.getTonAktual(), target.mid());
        StatusPanen status = AnalisaCalculator.getStatus(req.getTonAktual(), target.min(), target.mid());

        panen.setBulan(req.getBulan());
        panen.setTahun(req.getTahun());
        panen.setBulanAngka(req.getBulanAngka());
        if (req.getTanggal() != null) panen.setTanggal(req.getTanggal());
        panen.setTonAktual(req.getTonAktual());
        panen.setTargetMin(target.min());
        panen.setTargetMax(target.max());
        panen.setTargetMid(target.mid());
        panen.setStatusPanen(status);
        panen.setPersenKurang(persen);
        if (req.getHargaPerTon() != null) panen.setHargaPerTon(req.getHargaPerTon());
        panenRepository.save(panen);

        try { auditService.log(AuditAction.PANEN_UPDATE, userId, "Panen", panenId,
                Map.of("fields_changed", List.of("bulan","tahun","tonAktual","hargaPerTon"), "lahanId", lahanId)); }
        catch (Exception ignored) {}

        // Re-analyze after update
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { claudeService.analyzePanen(panen, lahan); }
        });

        return toResponse(panen, lahan, null);
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

    private PanenResponse toResponse(Panen p, Lahan lahan, AnalisaResponse analisa) {
        return PanenResponse.builder()
            .id(p.getId()).lahanId(p.getLahan().getId())
            .namaLahan(lahan != null ? lahan.getNamaLahan() : null)
            .luasHa(lahan != null ? lahan.getLuasHa() : null)
            .usiaPohon(lahan != null ? lahan.getUsiaPohon() : null)
            .bulan(p.getBulan()).tahun(p.getTahun()).bulanAngka(p.getBulanAngka()).tanggal(p.getTanggal())
            .tonAktual(p.getTonAktual()).targetMin(p.getTargetMin())
            .targetMax(p.getTargetMax()).targetMid(p.getTargetMid())
            .statusPanen(p.getStatusPanen().name()).persenKurang(p.getPersenKurang())
            .hargaPerTon(p.getHargaPerTon())
            .nilaiEstimasi(p.getHargaPerTon() != null
                ? p.getTonAktual().multiply(p.getHargaPerTon())
                : p.getTonAktual().multiply(java.math.BigDecimal.valueOf(2400000)))
            .catatan(p.getCatatan()).createdAt(p.getCreatedAt()).analisa(analisa).build();
    }
}
