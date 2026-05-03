package com.sawitku.repository;

import com.sawitku.entity.Panen;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface PanenRepository extends JpaRepository<Panen, Long> {
    List<Panen> findByLahanIdOrderByTahunDescBulanAngkaDesc(Long lahanId, Pageable pageable);
    List<Panen> findByLahanIdAndTahunOrderByBulanAngkaDesc(Long lahanId, Integer tahun);
    boolean existsByLahanIdAndTahunAndBulanAngka(Long lahanId, Integer tahun, Integer bulanAngka);
    Optional<Panen> findFirstByLahanIdOrderByTahunDescBulanAngkaDesc(Long lahanId);
    Optional<Panen> findByIdAndLahanId(Long id, Long lahanId);

    @Query("SELECT p.bulanAngka, SUM(p.tonAktual), SUM(p.tonAktual * p.hargaPerTon) "
         + "FROM Panen p WHERE p.lahan.id = :lahanId AND p.tahun = :tahun "
         + "GROUP BY p.bulanAngka ORDER BY p.bulanAngka")
    List<Object[]> sumByMonth(@Param("lahanId") Long lahanId, @Param("tahun") Integer tahun);

    @Query("SELECT p.bulanAngka, SUM(p.tonAktual) FROM Panen p "
         + "WHERE p.lahan.id = :lahanId AND p.tahun = :tahun "
         + "GROUP BY p.bulanAngka")
    List<Object[]> sumTonByMonth(@Param("lahanId") Long lahanId, @Param("tahun") Integer tahun);

    @Query("SELECT COUNT(DISTINCT p.bulanAngka) FROM Panen p "
         + "WHERE p.lahan.id = :lahanId AND p.tahun = :tahun")
    Long countDistinctMonths(@Param("lahanId") Long lahanId, @Param("tahun") Integer tahun);

    @Query("SELECT p.statusPanen FROM Panen p WHERE p.lahan.id = :lahanId "
         + "ORDER BY p.tahun DESC, p.bulanAngka DESC")
    List<String> findLatestStatusPanen(@Param("lahanId") Long lahanId, Pageable pageable);
}
