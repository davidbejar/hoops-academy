package com.hoopsacademy.game.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent.FoulKind;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The voided_by marks a re-projection must write: only those that differ from the stored rows (GAME-01, PIT scope). */
class VoidMarksTest {

    private final Script script = new Script().start(1, 600).shot(1, 590, Script.player(1), 2, true)
            .foul(1, 580, Script.player(2), FoulKind.PERSONAL);
    private final List<RecordedEvent> events = script.events();
    private final EventId shot = events.get(1).id();
    private final EventId foul = events.get(2).id();
    private final EventId firstVoid = Script.eventId(10);
    private final EventId secondVoid = Script.eventId(11);

    @Test
    void unchangedMarksAreNoChange() {
        VoidMarks marks = VoidMarks.between(List.of(stored(shot, firstVoid), stored(foul, null)),
                Map.of(shot, firstVoid));

        assertThat(marks.isEmpty()).isTrue();
        assertThat(marks.voided()).isEmpty();
        assertThat(marks.cleared()).isEmpty();
    }

    @Test
    void aNewMarkAndAMovedMarkAreVoided() {
        VoidMarks marks = VoidMarks.between(List.of(stored(shot, firstVoid), stored(foul, null)),
                Map.of(shot, secondVoid, foul, firstVoid));

        assertThat(marks.isEmpty()).isFalse();
        assertThat(marks.voided()).containsExactlyInAnyOrderEntriesOf(Map.of(shot, secondVoid, foul, firstVoid));
        assertThat(marks.cleared()).isEmpty();
    }

    @Test
    void aMarkTheProjectionNoLongerHasIsCleared() {
        VoidMarks marks = VoidMarks.between(List.of(stored(shot, firstVoid), stored(foul, secondVoid)),
                Map.of(foul, secondVoid));

        assertThat(marks.isEmpty()).isFalse();
        assertThat(marks.voided()).isEmpty();
        assertThat(marks.cleared()).containsExactly(shot);
    }

    @Test
    void aMarkOfAnEventNotReadYetIsVoided() {
        VoidMarks marks = VoidMarks.between(List.of(), Map.of(shot, firstVoid));

        assertThat(marks.voided()).containsExactlyEntriesOf(Map.of(shot, firstVoid));
        assertThat(marks.cleared()).isEmpty();
    }

    private StoredEvent stored(EventId id, EventId voidedBy) {
        RecordedEvent recorded = events.stream().filter(e -> e.id().equals(id)).findFirst().orElseThrow();
        return new StoredEvent(recorded, new Recorder(UUID.randomUUID(), "R"), Instant.parse("2026-11-01T10:00:00Z"),
                voidedBy);
    }
}
