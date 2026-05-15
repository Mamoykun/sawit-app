package com.sawitku.repository;

import com.sawitku.entity.Subscription;
import com.sawitku.entity.PaketSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {
    Optional<Subscription> findByUserId(Long userId);

    long countByPaket(PaketSubscription paket);

    @Query("SELECT s FROM Subscription s WHERE s.paket <> 'GRATIS' AND s.expiredAt IS NOT NULL AND s.expiredAt < :now")
    List<Subscription> findExpired(@Param("now") LocalDateTime now);

    @Query("SELECT s.paket, COUNT(s) FROM Subscription s "
         + "WHERE s.expiredAt > CURRENT_TIMESTAMP OR s.paket = 'GRATIS' "
         + "GROUP BY s.paket")
    List<Object[]> countActiveByPaket();
}
