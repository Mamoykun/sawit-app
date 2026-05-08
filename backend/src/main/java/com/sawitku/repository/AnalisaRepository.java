package com.sawitku.repository;

import com.sawitku.entity.Analisa;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface AnalisaRepository extends JpaRepository<Analisa, Long> {
    Optional<Analisa> findByPanenId(Long panenId);

    @Query("SELECT a FROM Analisa a WHERE a.aiResponseRaw LIKE '%local_advisor%' ORDER BY a.createdAt DESC")
    List<Analisa> findLocalFallbacks(Pageable pageable);
}
