package com.hoopsacademy.game.application;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.events.MatchEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.ArrayList;
import java.util.List;
import java.util.OptionalLong;
import java.util.UUID;

/**
 * Offline sync of a batch of events (contract submitMatchEvents). Locks the match row, so batches of one match are
 * applied one after the other; stores new events, reports duplicates by id, rejects per event (schema, authz,
 * cancelled match, client sequence conflict) and re-projects the whole match in the same transaction. Domain
 * inconsistencies never reject an event: they become projection warnings. Events are accepted in every status but
 * CANCELLED, so an offline device never loses events because the start/finish call travelled separately.
 */
@ApplicationScoped
public class IngestEventBatch {

    public static final int MAX_BATCH = 500;

    public enum Status { ACCEPTED, DUPLICATE, REJECTED }

    /**
     * Contract MatchEventRejectionReason. MATCH_NOT_STARTED is reserved: v1 accepts events of SCHEDULED matches so
     * offline devices never lose events (ADR-0014); it exists so a future policy needs no contract change.
     */
    public enum RejectionReason {
        SCHEMA_INVALID, NOT_AUTHORIZED, MATCH_CANCELLED, CLIENT_SEQ_CONFLICT, EVENT_ID_REUSED, MATCH_NOT_STARTED
    }

    /** One result per submitted event, in request order; serverSeq for ACCEPTED/DUPLICATE, reason for REJECTED. */
    public record Result(UUID eventId, Status status, Long serverSeq, RejectionReason reason, String message) {

        static Result stored(UUID id, Status status, long serverSeq) {
            return new Result(id, status, serverSeq, null, null);
        }

        static Result rejected(UUID id, RejectionReason reason, String message) {
            return new Result(id, Status.REJECTED, null, reason, message);
        }
    }

    public record BatchResult(List<Result> results, long lastServerSeq) {

        public BatchResult {
            results = List.copyOf(results);
        }
    }

    private final MatchRepository matches;
    private final MatchEventRepository events;
    private final MatchReprojection reprojection;
    private final CurrentCaller caller;

    IngestEventBatch(MatchRepository matches, MatchEventRepository events, MatchReprojection reprojection,
            CurrentCaller caller) {
        this.matches = matches;
        this.events = events;
        this.reprojection = reprojection;
        this.caller = caller;
    }

    /** @param recorderName display name stored with accepted events (from the caller's token) */
    @Transactional
    public BatchResult handle(MatchId matchId, List<SubmittedEvent> batch, String recorderName) {
        if (batch.isEmpty() || batch.size() > MAX_BATCH) {
            throw new IllegalArgumentException("A batch holds 1 to " + MAX_BATCH + " events");
        }
        Match match = matches.lockById(matchId).orElseThrow(() -> new NotFoundException("Match " + matchId + " not found"));
        EventLedger ledger = new EventLedger(events.findByMatch(matchId));
        AuthzContext authz = caller.authz();
        Recorder recorder = new Recorder(authz.personId(), recorderName);
        List<Result> results = new ArrayList<>(batch.size());
        for (SubmittedEvent submitted : batch) {
            results.add(admit(match, submitted, ledger, authz, recorder));
        }
        if (ledger.changed()) {
            reprojection.reproject(match);
        }
        return new BatchResult(results, ledger.lastServerSeq());
    }

    private Result admit(Match match, SubmittedEvent submitted, EventLedger ledger, AuthzContext authz, Recorder recorder) {
        if (submitted instanceof SubmittedEvent.Invalid invalid) {
            return Result.rejected(invalid.eventId(), RejectionReason.SCHEMA_INVALID, invalid.message());
        }
        MatchEvent event = ((SubmittedEvent.Valid) submitted).event();
        UUID id = event.id().value();
        OptionalLong known = ledger.serverSeqOf(event.id());
        if (known.isPresent()) {
            return Result.stored(id, Status.DUPLICATE, known.getAsLong());
        }
        if (match.status() == MatchStatus.CANCELLED) {
            return Result.rejected(id, RejectionReason.MATCH_CANCELLED, "The match is cancelled");
        }
        if (!EventAuthorization.mayRecord(authz, match, event, ledger::recorderOf)) {
            return Result.rejected(id, RejectionReason.NOT_AUTHORIZED, "Not allowed to record this " + event.type() + " event");
        }
        var taken = ledger.deviceSeqTakenBy(event);
        if (taken.isPresent()) {
            return Result.rejected(id, RejectionReason.CLIENT_SEQ_CONFLICT,
                    "(deviceId, clientSeq) is already used by event " + taken.get());
        }
        OptionalLong serverSeq = events.append(match.id(), event, recorder);
        if (serverSeq.isEmpty()) {
            return Result.rejected(id, RejectionReason.EVENT_ID_REUSED, "The event id is already used by another match");
        }
        ledger.accept(event, serverSeq.getAsLong(), recorder.personId());
        events.recordReceipt(match.id(), event.meta().deviceId(), event.meta().clientSeq());
        return Result.stored(id, Status.ACCEPTED, serverSeq.getAsLong());
    }
}
