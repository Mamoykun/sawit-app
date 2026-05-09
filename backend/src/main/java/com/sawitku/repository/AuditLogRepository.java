package com.sawitku.repository;

import com.sawitku.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {
    Page<AuditLog> findByUserIdOrderByOccurredAtDesc(Long userId, Pageable pageable);

    Page<AuditLog> findAllByOrderByOccurredAtDesc(Pageable pageable);

    Page<AuditLog> findByActionOrderByOccurredAtDesc(String action, Pageable pageable);

    @Query("SELECT COUNT(DISTINCT a.userId) FROM AuditLog a WHERE a.occurredAt > :since")
    long countDistinctUsersSince(@Param("since") Instant since);

    default long countDistinctUsersToday() {
        return countDistinctUsersSince(Instant.now().truncatedTo(ChronoUnit.DAYS));
    }

    @Query("SELECT COUNT(a) FROM AuditLog a WHERE a.action = :action AND a.occurredAt > :since")
    long countByActionAndOccurredAtAfter(@Param("action") String action, @Param("since") Instant since);

    List<AuditLog> findTop50ByOrderByOccurredAtDesc();
}
