package com.sawitku.repository;

import com.sawitku.entity.Diagnosa;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface DiagnosaRepository extends JpaRepository<Diagnosa, Long> {
    List<Diagnosa> findByLahanIdOrderByCreatedAtDesc(Long lahanId, Pageable pageable);
    Optional<Diagnosa> findByIdAndLahanId(Long id, Long lahanId);
}
