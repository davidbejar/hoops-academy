package com.hoopsacademy.game.domain.events;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class EventOrderingTest {

    private static RecordedEvent event(String id, int period, int clock, String recordedAt, long serverSeq) {
        EventMeta meta = new EventMeta(EventId.of(UUID.fromString(id)), "d", serverSeq, period, clock, Instant.parse(recordedAt));
        return new RecordedEvent(new MatchEvent.PeriodStart(meta), serverSeq);
    }

    @Test
    void ordersByPeriodThenClockDescendingThenDeviceTimeThenServerSeqThenId() {
        RecordedEvent p2 = event("00000000-0000-7000-8000-000000000001", 2, 600, "2026-11-01T10:00:00Z", 1);
        RecordedEvent p1Late = event("00000000-0000-7000-8000-000000000002", 1, 100, "2026-11-01T10:00:00Z", 2);
        RecordedEvent p1Early = event("00000000-0000-7000-8000-000000000003", 1, 500, "2026-11-01T10:05:00Z", 3);
        RecordedEvent sameClockLaterDevice = event("00000000-0000-7000-8000-000000000004", 1, 100, "2026-11-01T10:01:00Z", 4);
        RecordedEvent sameAllButSeq = event("00000000-0000-7000-8000-000000000005", 1, 100, "2026-11-01T10:01:00Z", 0);
        RecordedEvent idTieBreak = event("00000000-0000-7000-8000-000000000000", 1, 100, "2026-11-01T10:01:00Z", 0);

        List<RecordedEvent> sorted = EventOrdering.canonical(
                List.of(p2, p1Late, p1Early, sameClockLaterDevice, sameAllButSeq, idTieBreak));

        assertThat(sorted).containsExactly(p1Early, p1Late, idTieBreak, sameAllButSeq, sameClockLaterDevice, p2);
    }

    @Test
    void canonicalDropsRepeatedIdsKeepingTheEarliest() {
        RecordedEvent first = event("00000000-0000-7000-8000-000000000001", 1, 600, "2026-11-01T10:00:00Z", 1);
        RecordedEvent again = event("00000000-0000-7000-8000-000000000001", 1, 600, "2026-11-01T10:00:00Z", 7);

        assertThat(EventOrdering.canonical(List.of(again, first, first))).containsExactly(first);
    }
}
