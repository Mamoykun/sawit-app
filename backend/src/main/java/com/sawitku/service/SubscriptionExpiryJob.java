package com.sawitku.service;

import com.sawitku.entity.PaketSubscription;
import com.sawitku.entity.Subscription;
import com.sawitku.model.AuditAction;
import com.sawitku.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class SubscriptionExpiryJob {

    private final SubscriptionRepository subscriptionRepository;
    private final AuditService auditService;

    /** Run at 00:05 Asia/Jakarta every day. Downgrade expired paid subscriptions to GRATIS. */
    @Scheduled(cron = "0 5 0 * * *", zone = "Asia/Jakarta")
    @Transactional
    public void expireSubscriptions() {
        List<Subscription> expired = subscriptionRepository.findExpired(LocalDateTime.now());
        if (expired.isEmpty()) {
            log.debug("SubscriptionExpiryJob: no expired subscriptions");
            return;
        }

        log.info("SubscriptionExpiryJob: downgrading {} expired subscription(s)", expired.size());
        for (Subscription sub : expired) {
            String oldPaket = sub.getPaket().name();
            sub.setPaket(PaketSubscription.GRATIS);
            sub.setStatus("EXPIRED");
            sub.setExpiredAt(null);
            subscriptionRepository.save(sub);

            try {
                auditService.log(AuditAction.SUBSCRIPTION_EXPIRED,
                        sub.getUser().getId(), "Subscription", sub.getId(),
                        Map.of("previousPaket", oldPaket));
            } catch (Exception e) {
                log.warn("Failed to audit subscription expiry id={}: {}", sub.getId(), e.getMessage());
            }
        }
        log.info("SubscriptionExpiryJob: done, {} subscription(s) downgraded", expired.size());
    }
}
