package com.sawitku.repository;

import com.sawitku.entity.Panen;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface PanenRepository extends JpaRepository<Panen, Long> {
    List<Panen> findByLahanIdOrderByTahunDescBulanAngkaDesc(Long lahanId, Pageable pageable);
    List<Panen> findByLahanIdAndTahunOrderByBulanAngkaDesc(Long lahanId, Integer tahun);
    boolean existsByLahanIdAndTahunAndBulanAngka(Long lahanId, Integer tahun, Integer bulanAngka);
    Optional<Panen> findFirstByLahanIdOrderByTahunDescBulanAngkaDesc(Long lahanId);
    Optional<Panen> findByIdAndLahanId(Long id, Long lahanId);
}
