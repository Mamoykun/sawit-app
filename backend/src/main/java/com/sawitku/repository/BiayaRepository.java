package com.sawitku.repository;

import com.sawitku.entity.Biaya;
import org.springframework.data.jpa.repository.JpaRepository;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface BiayaRepository extends JpaRepository<Biaya, Long> {
    List<Biaya> findByLahanIdAndTahunOrderByBulanAngkaDescIdDesc(Long lahanId, Integer tahun);
    List<Biaya> findByLahanIdOrderByTahunDescBulanAngkaDescIdDesc(Long lahanId);
    Optional<Biaya> findByIdAndLahanId(Long id, Long lahanId);

    @org.springframework.data.jpa.repository.Query(
        "SELECT COALESCE(SUM(b.jumlah), 0) FROM Biaya b " +
        "WHERE b.lahan.id = :lahanId AND b.tahun = :tahun AND b.bulanAngka = :bulanAngka")
    BigDecimal sumByLahanAndPeriode(Long lahanId, Integer tahun, Integer bulanAngka);
}
