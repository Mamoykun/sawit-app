package com.sawitku.service;

import com.sawitku.entity.PaketSubscription;
import com.sawitku.exception.BusinessException;
import com.sawitku.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import java.time.YearMonth;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final LahanRepository lahanRepository;
    private final RedisTemplate<String, String> redisTemplate;

    public PaketSubscription getPaket(Long userId) {
        return subscriptionRepository.findByUserId(userId)
            .map(s -> s.getPaket())
            .orElse(PaketSubscription.GRATIS);
    }

    public void checkLimitLahan(Long userId) {
        PaketSubscription paket = getPaket(userId);
        long count = lahanRepository.countByUserIdAndIsActiveTrue(userId);
        int max = switch (paket) {
            case GRATIS -> 2;
            case PETANI -> 10;
            case PRO -> Integer.MAX_VALUE;
        };
        if (count >= max)
            throw new BusinessException(
                "Batas lahan untuk paket " + paket.name() + " adalah " + max + " lahan. Upgrade paket untuk menambah lebih banyak lahan.",
                "LAHAN_LIMIT_EXCEEDED"
            );
    }

    public void checkLimitAnalisaAI(Long userId) {
        PaketSubscription paket = getPaket(userId);
        int max = switch (paket) {
            case GRATIS -> 5;
            case PETANI -> 30;
            case PRO -> Integer.MAX_VALUE;
        };
        if (max == Integer.MAX_VALUE) return;

        String key = "analisa_count:" + userId + ":" + YearMonth.now();
        String val = redisTemplate.opsForValue().get(key);
        int count = val != null ? Integer.parseInt(val) : 0;
        if (count >= max)
            throw new BusinessException(
                "Batas analisa AI bulan ini untuk paket " + paket.name() + " adalah " + max + " kali.",
                "ANALISA_LIMIT_EXCEEDED"
            );
    }

    public void incrementAnalisaCount(Long userId) {
        String key = "analisa_count:" + userId + ":" + YearMonth.now();
        redisTemplate.opsForValue().increment(key);
        redisTemplate.expire(key, 35, TimeUnit.DAYS);
    }
}
