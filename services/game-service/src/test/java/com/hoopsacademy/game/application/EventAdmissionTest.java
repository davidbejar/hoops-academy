package com.hoopsacademy.game.application;

import static com.hoopsacademy.game.application.EventAuthorizationTest.COACH;
import static com.hoopsacademy.game.application.EventAuthorizationTest.LINKED;
import static com.hoopsacademy.game.application.EventAuthorizationTest.OTHER_COACH;
import static com.hoopsacademy.game.application.EventAuthorizationTest.match;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.application.EventAdmission.Admitted;
import com.hoopsacademy.game.application.EventAdmission.Duplicate;
import com.hoopsacademy.game.application.EventAdmission.Refused;
import com.hoopsacademy.game.application.IngestEventBatch.RejectionReason;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.events.MatchEvent;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The checks of one submitted event before it is stored, in their order (IngestEventBatch; PIT scope, WP88). */
class EventAdmissionTest {

    private final List<RecordedEvent> script = new Script().start(1, 600).shot(1, 590, LINKED, 2, true).events();
    private final MatchEvent start = script.get(0).event();
    private final MatchEvent shot = script.get(1).event();
    private final Instant shotRecordedAt = shot.meta().recordedAtClient();

    @Test
    void aNewEventOfTheCallersTeamIsAdmitted() {
        assertThat(new EventAdmission(match(), COACH, Optional.empty()).check(shot, ledger()))
                .isInstanceOf(Admitted.class);
    }

    @Test
    void aKnownIdIsADuplicateWithItsSequenceBeforeAnyOtherCheck() {
        Match cancelled = match();
        cancelled.cancel("rain", Instant.parse("2026-11-01T08:00:00Z"));
        EventLedger ledger = ledger(stored(start, 5));

        assertThat(new EventAdmission(cancelled, OTHER_COACH, Optional.of(Instant.EPOCH)).check(start, ledger))
                .isEqualTo(new Duplicate(5));
    }

    @Test
    void aCancelledMatchTakesNoNewEvent() {
        Match cancelled = match();
        cancelled.cancel("rain", Instant.parse("2026-11-01T08:00:00Z"));

        assertThat(new EventAdmission(cancelled, OTHER_COACH, Optional.empty()).check(shot, ledger()))
                .isEqualTo(new Refused(RejectionReason.MATCH_CANCELLED, "The match is cancelled"));
    }

    @Test
    void aCallerOutsideTheMatrixIsRefused() {
        assertThat(new EventAdmission(match(), OTHER_COACH, Optional.of(Instant.EPOCH)).check(shot, ledger()))
                .isEqualTo(new Refused(RejectionReason.NOT_AUTHORIZED, "Not allowed to record this SHOT event"));
    }

    @Test
    void anEventRecordedFromTheSeasonsCloseOnIsRefused() {
        assertThat(new EventAdmission(match(), COACH, Optional.of(shotRecordedAt)).check(shot, ledger()))
                .isEqualTo(new Refused(RejectionReason.SEASON_ENDED, "Recorded after the season of the team ended"));
        assertThat(new EventAdmission(match(), COACH, Optional.of(shotRecordedAt.minusMillis(1))).check(shot, ledger()))
                .isInstanceOf(Refused.class);
    }

    @Test
    void anEventRecordedBeforeTheSeasonClosedIsAdmitted() {
        assertThat(new EventAdmission(match(), COACH, Optional.of(shotRecordedAt.plusMillis(1))).check(shot, ledger()))
                .isInstanceOf(Admitted.class);
    }

    @Test
    void aDeviceSequenceTakenByAnotherEventIsAConflict() {
        MatchEvent sameSlot = Script.unique().start(1, 600).events().getFirst().event();
        EventLedger ledger = ledger(stored(start, 5));

        assertThat(new EventAdmission(match(), COACH, Optional.empty()).check(sameSlot, ledger)).isEqualTo(
                new Refused(RejectionReason.CLIENT_SEQ_CONFLICT,
                        "(deviceId, clientSeq) is already used by event " + start.id()));
    }

    private static EventLedger ledger(StoredEvent... stored) {
        return new EventLedger(List.of(stored));
    }

    private static StoredEvent stored(MatchEvent event, long serverSeq) {
        return new StoredEvent(new RecordedEvent(event, serverSeq), new Recorder(UUID.randomUUID(), "R"),
                Instant.parse("2026-11-01T10:00:00Z"), null);
    }
}
