package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.game.application.MatchEventRepository;
import com.hoopsacademy.game.application.UsageCounter;
import com.hoopsacademy.game.domain.MatchStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@ApplicationScoped
class JpaUsageCounter implements UsageCounter {

    private final EntityManager em;
    private final MatchEventRepository events;
    private final Clock clock;

    JpaUsageCounter(EntityManager em, MatchEventRepository events, Clock clock) {
        this.em = em;
        this.events = events;
        this.clock = clock;
    }

    @Override
    public Usage usage() {
        Map<MatchStatus, Long> byStatus = new java.util.EnumMap<>(MatchStatus.class);
        List<Object[]> rows = em.createQuery("select m.status, count(m) from MatchEntity m group by m.status", Object[].class)
                .getResultList();
        rows.forEach(row -> byStatus.put((MatchStatus) row[0], (Long) row[1]));
        long total = byStatus.values().stream().mapToLong(Long::longValue).sum();
        Map<String, Long> counters = new LinkedHashMap<>();
        counters.put("matches", total);
        counters.put("scheduledMatches", byStatus.getOrDefault(MatchStatus.SCHEDULED, 0L));
        counters.put("liveMatches", byStatus.getOrDefault(MatchStatus.LIVE, 0L));
        counters.put("finishedMatches", byStatus.getOrDefault(MatchStatus.FINISHED, 0L));
        counters.put("cancelledMatches", byStatus.getOrDefault(MatchStatus.CANCELLED, 0L));
        counters.put("matchEvents", events.count());
        counters.put("matchEventsLast30Days", events.countReceivedSince(clock.instant().minus(Duration.ofDays(30))));
        Instant last = em.createQuery("select max(m.updatedAt) from MatchEntity m", Instant.class).getSingleResult();
        return new Usage(counters, last);
    }
}
