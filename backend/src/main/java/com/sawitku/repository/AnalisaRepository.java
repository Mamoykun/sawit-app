package com.sawitku.repository;

import com.sawitku.entity.Analisa;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AnalisaRepository extends JpaRepository<Analisa, Long> {
    Optional<Analisa> findByPanenId(Long panenId);
}
