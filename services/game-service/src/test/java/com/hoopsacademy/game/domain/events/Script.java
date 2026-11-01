package com.hoopsacademy.game.domain.events;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.events.MatchEvent.FoulKind;
import com.hoopsacademy.game.domain.events.MatchEvent.ReboundKind;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;

/**
 * Builds a scripted match: every event gets the next server sequence number, a deterministic id
 * ({@code 00000000-0000-7000-8000-<seq>}) and a device timestamp one second after the previous event.
 */
public final class Script {

    public static final Instant BASE = Instant.parse("2026-11-01T10:00:00Z");

    private final List<RecordedEvent> events = new ArrayList<>();
    private final Long idPrefix;
    private String device = "tablet-1";

    public Script() {
        this(null);
    }

    private Script(Long idPrefix) {
        this.idPrefix = idPrefix;
    }

    /** A script whose event ids are unique across scripts (event ids are a table-wide primary key). */
    public static Script unique() {
        return new Script(java.util.concurrent.ThreadLocalRandom.current().nextLong());
    }

    public static PlayerId player(int n) {
        return PlayerId.of(UUID.fromString("00000000-0000-4000-8000-%012d".formatted(n)));
    }

    public static EventId eventId(long seq) {
        return EventId.of(UUID.fromString("00000000-0000-7000-8000-%012d".formatted(seq)));
    }

    public Script device(String deviceId) {
        this.device = deviceId;
        return this;
    }

    public Script start(int period, int clock) {
        return add(period, clock, MatchEvent.PeriodStart::new);
    }

    public Script end(int period, int clock) {
        return add(period, clock, MatchEvent.PeriodEnd::new);
    }

    public Script subIn(int period, int clock, PlayerId p) {
        return add(period, clock, m -> new MatchEvent.SubIn(m, p));
    }

    public Script subOut(int period, int clock, PlayerId p) {
        return add(period, clock, m -> new MatchEvent.SubOut(m, p));
    }

    public Script shot(int period, int clock, PlayerId p, int points, boolean made) {
        return add(period, clock, m -> new MatchEvent.Shot(m, p, points, made));
    }

    public Script assist(int period, int clock, PlayerId p) {
        return add(period, clock, m -> new MatchEvent.Assist(m, p));
    }

    public Script rebound(int period, int clock, PlayerId p, ReboundKind kind) {
        return add(period, clock, m -> new MatchEvent.Rebound(m, p, kind));
    }

    public Script turnover(int period, int clock, PlayerId p) {
        return add(period, clock, m -> new MatchEvent.Turnover(m, p));
    }

    public Script steal(int period, int clock, PlayerId p) {
        return add(period, clock, m -> new MatchEvent.Steal(m, p));
    }

    public Script block(int period, int clock, PlayerId p) {
        return add(period, clock, m -> new MatchEvent.Block(m, p));
    }

    public Script foul(int period, int clock, PlayerId p, FoulKind kind) {
        return add(period, clock, m -> new MatchEvent.Foul(m, p, kind));
    }

    public Script opponent(int period, int clock, int points) {
        return add(period, clock, m -> new MatchEvent.OpponentScore(m, points));
    }

    public Script timeout(int period, int clock) {
        return add(period, clock, m -> new MatchEvent.Timeout(m, MatchEvent.TimeoutSide.OWN));
    }

    public Script note(int period, int clock, String text) {
        return add(period, clock, m -> new MatchEvent.Note(m, null, text));
    }

    public Script voidOf(int period, int clock, EventId target) {
        return add(period, clock, m -> new MatchEvent.Void(m, target));
    }

    /** Id of the most recently added event. */
    public EventId last() {
        return events.get(events.size() - 1).id();
    }

    public List<RecordedEvent> events() {
        return List.copyOf(events);
    }

    private Script add(int period, int clock, Function<EventMeta, MatchEvent> factory) {
        long seq = events.size() + 1L;
        EventId id = idPrefix == null ? eventId(seq) : EventId.of(new UUID(idPrefix, seq));
        EventMeta meta = new EventMeta(id, device, seq, period, clock, BASE.plusSeconds(seq));
        events.add(new RecordedEvent(factory.apply(meta), seq));
        return this;
    }
}
