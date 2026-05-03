package com.sawitku.repository;

import com.sawitku.entity.Biaya;
import com.sawitku.entity.KategoriBiaya;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface BiayaRepository extends JpaRepository<Biaya, Long> {
    List<Biaya> findByLahanIdAndTahunOrderByBulanAngkaDescIdDesc(Long lahanId, Integer tahun);
    List<Biaya> findByLahanIdOrderByTahunDescBulanAngkaDescIdDesc(Long lahanId);
    Optional<Biaya> findByIdAndLahanId(Long id, Long lahanId);

    @Query("SELECT COALESCE(SUM(b.jumlah), 0) FROM Biaya b " +
           "WHERE b.lahan.id = :lahanId AND b.tahun = :tahun AND b.bulanAngka = :bulanAngka")
    BigDecimal sumByLahanAndPeriode(Long lahanId, Integer tahun, Integer bulanAngka);

    @Query("SELECT b FROM Biaya b WHERE b.lahan.id = :lahanId AND b.kategori = :kategori " +
           "AND ((b.tahun > :sinceTahun) OR (b.tahun = :sinceTahun AND b.bulanAngka >= :sinceBulan)) " +
           "ORDER BY b.tahun DESC, b.bulanAngka DESC")
    List<Biaya> findByLahanIdAndKategoriRecent(
        @Param("lahanId") Long lahanId,
        @Param("kategori") KategoriBiaya kategori,
        @Param("sinceTahun") Integer sinceTahun,
        @Param("sinceBulan") Integer sinceBulan
    );

    @Query("SELECT b.bulanAngka, SUM(b.jumlah) FROM Biaya b "
         + "WHERE b.lahan.id = :lahanId AND b.tahun = :tahun "
         + "GROUP BY b.bulanAngka ORDER BY b.bulanAngka")
    List<Object[]> sumByMonth(@Param("lahanId") Long lahanId, @Param("tahun") Integer tahun);

    @Query("SELECT b.kategori, SUM(b.jumlah) FROM Biaya b "
         + "WHERE b.lahan.id = :lahanId AND b.tahun = :tahun "
         + "GROUP BY b.kategori")
    List<Object[]> sumByKategori(@Param("lahanId") Long lahanId, @Param("tahun") Integer tahun);
}
