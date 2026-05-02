package com.sawitku.service;

import com.sawitku.dto.request.LahanRequest;
import com.sawitku.dto.response.LahanResponse;
import com.sawitku.entity.Lahan;
import com.sawitku.entity.User;
import com.sawitku.exception.*;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.*;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class LahanService {

    private final LahanRepository lahanRepository;
    private final UserRepository userRepository;
    private final PanenRepository panenRepository;
    private final SubscriptionService subscriptionService;
    private final AuditService auditService;

    @Transactional
    public LahanResponse createLahan(Long userId, LahanRequest req) {
        subscriptionService.checkLimitLahan(userId);
        User user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User tidak ditemukan"));
        int currentYear = LocalDate.now().getYear();
        Integer tahunTanam = req.getTahunTanam();
        Integer usiaPohon = req.getUsiaPohon();
        if (tahunTanam == null && usiaPohon != null) tahunTanam = currentYear - usiaPohon;
        if (usiaPohon == null && tahunTanam != null) usiaPohon = currentYear - tahunTanam;
        Lahan lahan = Lahan.builder()
            .user(user).namaLahan(req.getNamaLahan())
            .luasHa(req.getLuasHa()).usiaPohon(usiaPohon).tahunTanam(tahunTanam)
            .jumlahPohon(req.getJumlahPohon()).lokasi(req.getLokasi())
            .latitude(req.getLatitude()).longitude(req.getLongitude())
            .catatan(req.getCatatan()).isActive(true).build();
        lahanRepository.save(lahan);
        try { auditService.log(AuditAction.LAHAN_CREATE, userId, "Lahan", lahan.getId(), null); }
        catch (Exception ignored) {}
        return toResponse(lahan);
    }

    @Transactional
    public LahanResponse updateLahan(Long userId, Long lahanId, LahanRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        int currentYear = LocalDate.now().getYear();
        Integer tahunTanam = req.getTahunTanam();
        Integer usiaPohon = req.getUsiaPohon();
        if (tahunTanam == null && usiaPohon != null) tahunTanam = currentYear - usiaPohon;
        if (usiaPohon == null && tahunTanam != null) usiaPohon = currentYear - tahunTanam;
        lahan.setNamaLahan(req.getNamaLahan());
        lahan.setLuasHa(req.getLuasHa());
        lahan.setUsiaPohon(usiaPohon);
        lahan.setTahunTanam(tahunTanam);
        lahan.setJumlahPohon(req.getJumlahPohon());
        lahan.setLokasi(req.getLokasi());
        lahan.setLatitude(req.getLatitude());
        lahan.setLongitude(req.getLongitude());
        lahan.setCatatan(req.getCatatan());
        lahanRepository.save(lahan);
        try { auditService.log(AuditAction.LAHAN_UPDATE, userId, "Lahan", lahanId,
                Map.of("fields_changed", List.of("namaLahan","luasHa","usiaPohon","tahunTanam","jumlahPohon","lokasi","catatan"))); }
        catch (Exception ignored) {}
        return toResponse(lahan);
    }

    @Transactional
    public void deleteLahan(Long userId, Long lahanId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        lahan.setIsActive(false);
        lahanRepository.save(lahan);
        try { auditService.log(AuditAction.LAHAN_DELETE, userId, "Lahan", lahanId, null); }
        catch (Exception ignored) {}
    }

    public List<LahanResponse> getMyLahan(Long userId) {
        return lahanRepository.findByUserIdAndIsActiveTrue(userId)
            .stream().map(this::toResponse).toList();
    }

    public LahanResponse getLahanById(Long userId, Long lahanId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        return toResponse(lahan);
    }

    private LahanResponse toResponse(Lahan lahan) {
        int usia = lahan.getTahunTanam() != null
            ? LocalDate.now().getYear() - lahan.getTahunTanam()
            : lahan.getUsiaPohon();
        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), usia);
        LahanResponse.PanenSummary panenSummary = panenRepository
            .findFirstByLahanIdOrderByTahunDescBulanAngkaDesc(lahan.getId())
            .map(p -> LahanResponse.PanenSummary.builder()
                .id(p.getId()).bulan(p.getBulan()).tahun(p.getTahun())
                .tonAktual(p.getTonAktual()).targetMid(p.getTargetMid())
                .statusPanen(p.getStatusPanen().name()).persenKurang(p.getPersenKurang()).build())
            .orElse(null);

        return LahanResponse.builder()
            .id(lahan.getId()).namaLahan(lahan.getNamaLahan())
            .luasHa(lahan.getLuasHa()).usiaPohon(usia).tahunTanam(lahan.getTahunTanam())
            .jumlahPohon(lahan.getJumlahPohon()).lokasi(lahan.getLokasi())
            .latitude(lahan.getLatitude()).longitude(lahan.getLongitude())
            .catatan(lahan.getCatatan()).isActive(lahan.getIsActive())
            .createdAt(lahan.getCreatedAt()).faseProduksi(target.fase())
            .panenTerakhir(panenSummary)
            .statusTerkini(panenSummary != null ? panenSummary.getStatusPanen() : null)
            .build();
    }
}
