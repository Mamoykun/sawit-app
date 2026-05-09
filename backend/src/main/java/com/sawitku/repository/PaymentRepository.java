package com.sawitku.repository;

import com.sawitku.entity.Payment;
import com.sawitku.entity.PaymentStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    Optional<Payment> findByOrderId(String orderId);
    List<Payment> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Payment> findAllByOrderByCreatedAtDesc(Pageable pageable);

    @Query("SELECT COALESCE(SUM(p.grossAmount), 0) FROM Payment p WHERE p.status = :status")
    BigDecimal sumGrossAmountByStatus(@Param("status") PaymentStatus status);
}
