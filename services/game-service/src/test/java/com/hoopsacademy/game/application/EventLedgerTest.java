package com.hoopsacademy.game.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** What a batch knows about a match's events while it is admitted (PIT scope, WP88). */
class EventLedgerTest {

    private static final UUID ANA = UUID.randomUUID();
    private static final UUID BEA = UUID.randomUUID();

    private final List<RecordedEvent> script = new Script().start(1, 600).end(1, 0).start(2, 600).events();

    @Test
    void storedEventsAreKnownByIdWithTheirSequenceAndRecorder() {
        EventLedger ledger = new EventLedger(List.of(stored(script.get(1), 7, BEA), stored(script.get(0), 3, ANA)));

        assertThat(ledger.serverSeqOf(script.get(0).id())).hasValue(3);
        assertThat(ledger.serverSeqOf(script.get(1).id())).hasValue(7);
        assertThat(ledger.serverSeqOf(script.get(2).id())).isEmpty();
        assertThat(ledger.recorderOf(script.get(1).id())).contains(BEA);
        assertThat(ledger.recorderOf(script.get(2).id())).isEmpty();
        assertThat(ledger.lastServerSeq()).as("the highest, whatever the order").isEqualTo(7);
        assertThat(ledger.changed()).isFalse();
    }

    @Test
    void anEmptyMatchStartsAtZero() {
        assertThat(new EventLedger(List.of()).lastServerSeq()).isZero();
    }

    @Test
    void anAcceptedEventIsKnownAndMarksTheLedgerChanged() {
        EventLedger ledger = new EventLedger(List.of(stored(script.get(0), 3, ANA)));

        ledger.accept(script.get(1).event(), 4, BEA);

        assertThat(ledger.changed()).isTrue();
        assertThat(ledger.serverSeqOf(script.get(1).id())).hasValue(4);
        assertThat(ledger.recorderOf(script.get(1).id())).contains(BEA);
        assertThat(ledger.lastServerSeq()).isEqualTo(4);
    }

    @Test
    void aDeviceSequenceIsTakenOnlyByAnotherEvent() {
        EventLedger ledger = new EventLedger(List.of(stored(script.get(0), 3, ANA)));
        RecordedEvent sameSlot = Script.unique().start(1, 600).events().getFirst();
        RecordedEvent otherDevice = new Script().device("tablet-2").start(1, 600).events().getFirst();

        assertThat(ledger.deviceSeqTakenBy(script.get(0).event())).as("the event itself").isEmpty();
        assertThat(ledger.deviceSeqTakenBy(sameSlot.event())).contains(script.get(0).id());
        assertThat(ledger.deviceSeqTakenBy(script.get(1).event())).as("another client sequence").isEmpty();
        assertThat(ledger.deviceSeqTakenBy(otherDevice.event())).as("another device").isEmpty();
    }

    private static StoredEvent stored(RecordedEvent event, long serverSeq, UUID recorder) {
        return new StoredEvent(new RecordedEvent(event.event(), serverSeq), new Recorder(recorder, "R"),
                Instant.parse("2026-11-01T10:00:00Z"), null);
    }
}
