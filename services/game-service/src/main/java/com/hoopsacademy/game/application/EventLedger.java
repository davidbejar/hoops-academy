package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalLong;
import java.util.UUID;

/** The events of one match known while a batch is admitted: stored ones plus those accepted so far. */
final class EventLedger {

    private record Entry(long serverSeq, UUID recordedBy) {}

    private record DeviceSeq(String deviceId, long clientSeq) {}

    private final Map<EventId, Entry> byId = new HashMap<>();
    private final Map<DeviceSeq, EventId> byDeviceSeq = new HashMap<>();
    private long lastServerSeq;
    private boolean changed;

    EventLedger(List<StoredEvent> stored) {
        stored.forEach(e -> remember(e.recorded().event(), e.recorded().serverSeq(), e.recordedBy().personId()));
    }

    OptionalLong serverSeqOf(EventId id) {
        Entry entry = byId.get(id);
        return entry == null ? OptionalLong.empty() : OptionalLong.of(entry.serverSeq());
    }

    Optional<UUID> recorderOf(EventId id) {
        return Optional.ofNullable(byId.get(id)).map(Entry::recordedBy);
    }

    /** The id of another event already using this event's (deviceId, clientSeq), if any. */
    Optional<EventId> deviceSeqTakenBy(MatchEvent event) {
        return Optional.ofNullable(byDeviceSeq.get(deviceSeq(event))).filter(id -> !id.equals(event.id()));
    }

    void accept(MatchEvent event, long serverSeq, UUID recordedBy) {
        remember(event, serverSeq, recordedBy);
        changed = true;
    }

    boolean changed() {
        return changed;
    }

    long lastServerSeq() {
        return lastServerSeq;
    }

    private void remember(MatchEvent event, long serverSeq, UUID recordedBy) {
        byId.put(event.id(), new Entry(serverSeq, recordedBy));
        byDeviceSeq.put(deviceSeq(event), event.id());
        lastServerSeq = Math.max(lastServerSeq, serverSeq);
    }

    private static DeviceSeq deviceSeq(MatchEvent event) {
        return new DeviceSeq(event.meta().deviceId(), event.meta().clientSeq());
    }
}
