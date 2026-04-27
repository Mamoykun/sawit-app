package com.sawitku.repository;

import com.sawitku.entity.Lahan;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface LahanRepository extends JpaRepository<Lahan, Long> {
    List<Lahan> findByUserIdAndIsActiveTrue(Long userId);
    long countByUserIdAndIsActiveTrue(Long userId);
    Optional<Lahan> findByIdAndUserId(Long id, Long userId);
}
