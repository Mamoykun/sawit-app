package com.sawitku.service;

import com.sawitku.dto.request.LahanRequest;
import com.sawitku.dto.response.LahanResponse;
import com.sawitku.entity.Lahan;
import com.sawitku.entity.User;
import com.sawitku.exception.*;
import com.sawitku.repository.*;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LahanService {

    private final LahanRepository lahanRepository;
    private final UserRepository userRepository;
    private final PanenRepository panenRepository;
    private final SubscriptionService subscriptionService;

    @Transactional
    public LahanResponse createLahan(Long userId, LahanRequest req) {
        subscriptionService.checkLimitLahan(userId);
        User user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User tidak ditemukan"));
        Lahan lahan = Lahan.builder()
            .user(user).namaLahan(req.getNamaLahan())
            .luasHa(req.getLuasHa()).usiaPohon(req.getUsiaPohon())
            .jumlahPohon(req.getJumlahPohon()).lokasi(req.getLokasi())
            .latitude(req.getLatitude()).longitude(req.getLongitude())
            .catatan(req.getCatatan()).isActive(true).build();
        lahanRepository.save(lahan);
        return toResponse(lahan);
    }

    @Transactional
    public LahanResponse updateLahan(Long userId, Long lahanId, LahanRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        lahan.setNamaLahan(req.getNamaLahan());
        lahan.setLuasHa(req.getLuasHa());
        lahan.setUsiaPohon(req.getUsiaPohon());
        lahan.setJumlahPohon(req.getJumlahPohon());
        lahan.setLokasi(req.getLokasi());
        lahan.setLatitude(req.getLatitude());
        lahan.setLongitude(req.getLongitude());
        lahan.setCatatan(req.getCatatan());
        lahanRepository.save(lahan);
        return toResponse(lahan);
    }

    @Transactional
    public void deleteLahan(Long userId, Long lahanId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        lahan.setIsActive(false);
        lahanRepository.save(lahan);
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
        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        LahanResponse.PanenSummary panenSummary = panenRepository
            .findFirstByLahanIdOrderByTahunDescBulanAngkaDesc(lahan.getId())
            .map(p -> LahanResponse.PanenSummary.builder()
                .id(p.getId()).bulan(p.getBulan()).tahun(p.getTahun())
                .tonAktual(p.getTonAktual()).targetMid(p.getTargetMid())
                .statusPanen(p.getStatusPanen().name()).persenKurang(p.getPersenKurang()).build())
            .orElse(null);

        return LahanResponse.builder()
            .id(lahan.getId()).namaLahan(lahan.getNamaLahan())
            .luasHa(lahan.getLuasHa()).usiaPohon(lahan.getUsiaPohon())
            .jumlahPohon(lahan.getJumlahPohon()).lokasi(lahan.getLokasi())
            .latitude(lahan.getLatitude()).longitude(lahan.getLongitude())
            .catatan(lahan.getCatatan()).isActive(lahan.getIsActive())
            .createdAt(lahan.getCreatedAt()).faseProduksi(target.fase())
            .panenTerakhir(panenSummary)
            .statusTerkini(panenSummary != null ? panenSummary.getStatusPanen() : null)
            .build();
    }
}
