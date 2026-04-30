package com.sawitku.service;

import com.sawitku.dto.request.BiayaRequest;
import com.sawitku.dto.response.BiayaResponse;
import com.sawitku.entity.Biaya;
import com.sawitku.entity.Lahan;
import com.sawitku.exception.ResourceNotFoundException;
import com.sawitku.repository.BiayaRepository;
import com.sawitku.repository.LahanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BiayaService {

    private final BiayaRepository biayaRepository;
    private final LahanRepository lahanRepository;

    @Transactional
    public BiayaResponse createBiaya(Long userId, Long lahanId, BiayaRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        Biaya biaya = Biaya.builder()
            .lahan(lahan)
            .bulan(req.getBulan())
            .tahun(req.getTahun())
            .bulanAngka(req.getBulanAngka())
            .kategori(req.getKategori())
            .jumlah(req.getJumlah())
            .keterangan(req.getKeterangan())
            .createdAt(LocalDateTime.now())
            .build();
        biayaRepository.save(biaya);
        return toResponse(biaya);
    }

    public List<BiayaResponse> getBiayaByLahan(Long userId, Long lahanId, Integer tahun) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        List<Biaya> list = (tahun != null)
            ? biayaRepository.findByLahanIdAndTahunOrderByBulanAngkaDescIdDesc(lahanId, tahun)
            : biayaRepository.findByLahanIdOrderByTahunDescBulanAngkaDescIdDesc(lahanId);
        return list.stream().map(this::toResponse).toList();
    }

    @Transactional
    public BiayaResponse updateBiaya(Long userId, Long lahanId, Long biayaId, BiayaRequest req) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Biaya biaya = biayaRepository.findByIdAndLahanId(biayaId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Biaya tidak ditemukan"));

        biaya.setBulan(req.getBulan());
        biaya.setTahun(req.getTahun());
        biaya.setBulanAngka(req.getBulanAngka());
        biaya.setKategori(req.getKategori());
        biaya.setJumlah(req.getJumlah());
        biaya.setKeterangan(req.getKeterangan());
        biayaRepository.save(biaya);
        return toResponse(biaya);
    }

    @Transactional
    public void deleteBiaya(Long userId, Long lahanId, Long biayaId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Biaya biaya = biayaRepository.findByIdAndLahanId(biayaId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Biaya tidak ditemukan"));
        biayaRepository.delete(biaya);
    }

    public BigDecimal getTotalBiayaPeriode(Long lahanId, Integer tahun, Integer bulanAngka) {
        BigDecimal total = biayaRepository.sumByLahanAndPeriode(lahanId, tahun, bulanAngka);
        return total != null ? total : BigDecimal.ZERO;
    }

    private BiayaResponse toResponse(Biaya b) {
        return BiayaResponse.builder()
            .id(b.getId())
            .lahanId(b.getLahan().getId())
            .bulan(b.getBulan())
            .tahun(b.getTahun())
            .bulanAngka(b.getBulanAngka())
            .kategori(b.getKategori().name())
            .jumlah(b.getJumlah())
            .keterangan(b.getKeterangan())
            .createdAt(b.getCreatedAt())
            .build();
    }
}
