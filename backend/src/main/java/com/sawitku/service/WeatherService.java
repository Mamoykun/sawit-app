package com.sawitku.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
public class WeatherService {

    public record WeatherSummary(
        double totalRainfall90d,   // mm
        double avgTemp90d,         // °C
        int dryDayStreak,          // hari kering terpanjang (curah hujan < 1mm)
        int wetDays                // jumlah hari hujan >= 1mm
    ) {}

    private record LatLon(double lat, double lon) {}

    private static final String GEOCODE_URL =
        "https://geocoding-api.open-meteo.com/v1/search?name={name}&count=1&language=id";
    private static final String ARCHIVE_URL =
        "https://archive-api.open-meteo.com/v1/archive" +
        "?latitude={lat}&longitude={lon}" +
        "&start_date={start}&end_date={end}" +
        "&daily=precipitation_sum,temperature_2m_mean" +
        "&timezone=Asia/Jakarta";

    private final ObjectMapper objectMapper;

    @Autowired(required = false)
    private RedisTemplate<String, String> redisTemplate;

    public WeatherService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public Optional<WeatherSummary> getSummary(String lokasi) {
        if (lokasi == null || lokasi.isBlank()) return Optional.empty();

        String normalized = lokasi.trim().toLowerCase();
        String weatherKey = "weather:" + normalized;

        // Try weather cache first
        try {
            if (redisTemplate != null) {
                String cached = redisTemplate.opsForValue().get(weatherKey);
                if (cached != null) {
                    WeatherSummary summary = objectMapper.readValue(cached, WeatherSummary.class);
                    return Optional.of(summary);
                }
            }
        } catch (Exception e) {
            log.debug("Weather cache read miss for {}: {}", normalized, e.getMessage());
        }

        // Geocode lokasi to lat/lon
        Optional<LatLon> latLon = geocode(normalized);
        if (latLon.isEmpty()) return Optional.empty();

        // Fetch weather archive
        Optional<WeatherSummary> summary = fetchWeather(latLon.get());
        summary.ifPresent(ws -> {
            try {
                if (redisTemplate != null) {
                    String json = objectMapper.writeValueAsString(ws);
                    redisTemplate.opsForValue().set(weatherKey, json, 24, TimeUnit.HOURS);
                }
            } catch (Exception e) {
                log.debug("Weather cache write failed for {}: {}", normalized, e.getMessage());
            }
        });

        return summary;
    }

    private Optional<LatLon> geocode(String normalized) {
        String geocodeKey = "geocode:" + normalized;

        // Try geocode cache
        try {
            if (redisTemplate != null) {
                String cached = redisTemplate.opsForValue().get(geocodeKey);
                if (cached != null) {
                    Map<?, ?> map = objectMapper.readValue(cached, Map.class);
                    double lat = ((Number) map.get("lat")).doubleValue();
                    double lon = ((Number) map.get("lon")).doubleValue();
                    return Optional.of(new LatLon(lat, lon));
                }
            }
        } catch (Exception e) {
            log.debug("Geocode cache read miss for {}: {}", normalized, e.getMessage());
        }

        // Call geocoding API
        try {
            RestTemplate rest = new RestTemplate();
            ResponseEntity<Map> response = rest.getForEntity(GEOCODE_URL, Map.class, normalized);
            if (response.getBody() == null) return Optional.empty();

            List<?> results = (List<?>) response.getBody().get("results");
            if (results == null || results.isEmpty()) {
                log.debug("Geocoding returned no results for '{}'", normalized);
                return Optional.empty();
            }

            Map<?, ?> first = (Map<?, ?>) results.get(0);
            double lat = ((Number) first.get("latitude")).doubleValue();
            double lon = ((Number) first.get("longitude")).doubleValue();
            LatLon latLon = new LatLon(lat, lon);

            // Cache geocode result for 30 days
            try {
                if (redisTemplate != null) {
                    String json = objectMapper.writeValueAsString(Map.of("lat", lat, "lon", lon));
                    redisTemplate.opsForValue().set(geocodeKey, json, 30, TimeUnit.DAYS);
                }
            } catch (Exception ex) {
                log.debug("Geocode cache write failed: {}", ex.getMessage());
            }

            return Optional.of(latLon);
        } catch (Exception e) {
            log.warn("Geocoding failed for '{}': {}", normalized, e.getMessage());
            return Optional.empty();
        }
    }

    @SuppressWarnings("unchecked")
    private Optional<WeatherSummary> fetchWeather(LatLon latLon) {
        try {
            LocalDate today = LocalDate.now();
            LocalDate start = today.minusDays(90);
            DateTimeFormatter fmt = DateTimeFormatter.ISO_LOCAL_DATE;

            RestTemplate rest = new RestTemplate();
            ResponseEntity<Map> response = rest.getForEntity(
                ARCHIVE_URL, Map.class,
                latLon.lat(), latLon.lon(),
                start.format(fmt), today.format(fmt)
            );

            if (response.getBody() == null) return Optional.empty();
            Map<?, ?> daily = (Map<?, ?>) response.getBody().get("daily");
            if (daily == null) return Optional.empty();

            List<Number> precipList = (List<Number>) daily.get("precipitation_sum");
            List<Number> tempList = (List<Number>) daily.get("temperature_2m_mean");
            if (precipList == null || tempList == null) return Optional.empty();

            double totalRain = 0;
            int wetDays = 0;
            int currentStreak = 0;
            int maxStreak = 0;

            for (Number v : precipList) {
                double mm = v != null ? v.doubleValue() : 0.0;
                totalRain += mm;
                if (mm >= 1.0) {
                    wetDays++;
                    currentStreak = 0;
                } else {
                    currentStreak++;
                    if (currentStreak > maxStreak) maxStreak = currentStreak;
                }
            }

            double totalTemp = 0;
            int tempCount = 0;
            for (Number v : tempList) {
                if (v != null) {
                    totalTemp += v.doubleValue();
                    tempCount++;
                }
            }
            double avgTemp = tempCount > 0 ? totalTemp / tempCount : 0;

            return Optional.of(new WeatherSummary(
                Math.round(totalRain * 10.0) / 10.0,
                Math.round(avgTemp * 10.0) / 10.0,
                maxStreak,
                wetDays
            ));
        } catch (Exception e) {
            log.warn("Weather archive fetch failed: {}", e.getMessage());
            return Optional.empty();
        }
    }
}
