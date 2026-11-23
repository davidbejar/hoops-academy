package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.events.EventId;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * The {@code voided_by} marks a re-projection changes, compared with what the stored rows carry: events newly voided or
 * now voided by another VOID ({@code voided}, target to VOID) and events no longer voided ({@code cleared}).
 */
public record VoidMarks(Map<EventId, EventId> voided, Set<EventId> cleared) {

    public VoidMarks {
        voided = Map.copyOf(voided);
        cleared = Set.copyOf(cleared);
    }

    /**
     * @param stored the events as read, with their marks; an event missing here (appended since) carries none
     * @param projected the projection's marks, target to VOID
     */
    static VoidMarks between(List<StoredEvent> stored, Map<EventId, EventId> projected) {
        Map<EventId, EventId> before = new HashMap<>();
        stored.stream().filter(e -> e.voidedBy() != null).forEach(e -> before.put(e.recorded().id(), e.voidedBy()));
        Map<EventId, EventId> voided = new HashMap<>();
        projected.forEach((target, by) -> {
            if (!Objects.equals(before.get(target), by)) {
                voided.put(target, by);
            }
        });
        Set<EventId> cleared = new HashSet<>(before.keySet());
        cleared.removeAll(projected.keySet());
        return new VoidMarks(voided, cleared);
    }

    public boolean isEmpty() {
        return voided.isEmpty() && cleared.isEmpty();
    }
}
