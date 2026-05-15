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

    @Query("SELECT a FROM AuditLog a WHERE " +
           "(:action IS NULL OR a.action = :action) AND " +
           "(:from IS NULL OR a.occurredAt >= :from) AND " +
           "(:to IS NULL OR a.occurredAt <= :to) AND " +
           "(:success IS NULL OR a.success = :success) " +
           "ORDER BY a.occurredAt DESC")
    Page<AuditLog> findFiltered(
            @Param("action") String action,
            @Param("from") Instant from,
            @Param("to") Instant to,
            @Param("success") Boolean success,
            Pageable pageable);

    long countBySuccess(boolean success);

    @Query("SELECT COUNT(a) FROM AuditLog a WHERE a.success = :success AND a.occurredAt > :since")
    long countBySuccessAndOccurredAtAfter(@Param("success") boolean success, @Param("since") Instant since);
}
