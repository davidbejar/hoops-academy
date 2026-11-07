package com.hoopsacademy.game.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.game.application.IngestEventBatch.RejectionReason;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.events.MatchEvent;
import java.time.Instant;
import java.util.Optional;
import java.util.OptionalLong;

/**
 * The checks of one valid submitted event before it is stored ({@link IngestEventBatch}; kept apart for PIT in WP88),
 * in this order: a known id is a duplicate; then a cancelled match, the authz matrix ({@link EventAuthorization}), an
 * event recorded once the season of the match's team had closed, and a (deviceId, clientSeq) another event uses.
 */
final class EventAdmission {

    /** The outcome of the checks. */
    sealed interface Verdict {}

    /** The id is known: the event is stored as {@code serverSeq}. */
    record Duplicate(long serverSeq) implements Verdict {}

    /** The event is rejected. */
    record Refused(RejectionReason reason, String message) implements Verdict {}

    /** The event may be stored. */
    record Admitted() implements Verdict {}

    private final Match match;
    private final AuthzContext authz;
    private final Optional<Instant> seasonClosed;

    /** @param seasonClosed when the season of the match's team closed, if it has */
    EventAdmission(Match match, AuthzContext authz, Optional<Instant> seasonClosed) {
        this.match = match;
        this.authz = authz;
        this.seasonClosed = seasonClosed;
    }

    Verdict check(MatchEvent event, EventLedger ledger) {
        OptionalLong known = ledger.serverSeqOf(event.id());
        if (known.isPresent()) {
            return new Duplicate(known.getAsLong());
        }
        if (match.status() == MatchStatus.CANCELLED) {
            return new Refused(RejectionReason.MATCH_CANCELLED, "The match is cancelled");
        }
        if (!EventAuthorization.mayRecord(authz, match, event, ledger::recorderOf)) {
            return new Refused(RejectionReason.NOT_AUTHORIZED, "Not allowed to record this " + event.type() + " event");
        }
        if (recordedAfterTheSeason(event)) {
            return new Refused(RejectionReason.SEASON_ENDED, "Recorded after the season of the team ended");
        }
        return ledger.deviceSeqTakenBy(event).<Verdict>map(taken -> new Refused(RejectionReason.CLIENT_SEQ_CONFLICT,
                "(deviceId, clientSeq) is already used by event " + taken)).orElseGet(Admitted::new);
    }

    private boolean recordedAfterTheSeason(MatchEvent event) {
        return seasonClosed.filter(closed -> !event.meta().recordedAtClient().isBefore(closed)).isPresent();
    }
}
