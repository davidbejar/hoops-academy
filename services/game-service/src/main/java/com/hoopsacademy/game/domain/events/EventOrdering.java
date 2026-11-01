package com.hoopsacademy.game.domain.events;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Game order of events, independent of arrival: period ascending, clock descending (the clock counts down),
 * device time ascending, server sequence ascending and finally the event id, so the order is total.
 */
public final class EventOrdering {

    public static final Comparator<RecordedEvent> GAME_ORDER = Comparator
            .comparingInt((RecordedEvent e) -> e.meta().period())
            .thenComparing(e -> e.meta().clockSecondsRemaining(), Comparator.reverseOrder())
            .thenComparing(e -> e.meta().recordedAtClient())
            .thenComparingLong(RecordedEvent::serverSeq)
            .thenComparing(RecordedEvent::id);

    private EventOrdering() {}

    /** The events in game order, each id once (the earliest occurrence in game order wins). */
    public static List<RecordedEvent> canonical(Collection<RecordedEvent> events) {
        List<RecordedEvent> sorted = new ArrayList<>(events);
        sorted.sort(GAME_ORDER);
        Set<EventId> seen = new HashSet<>();
        return sorted.stream().filter(e -> seen.add(e.id())).toList();
    }
}
