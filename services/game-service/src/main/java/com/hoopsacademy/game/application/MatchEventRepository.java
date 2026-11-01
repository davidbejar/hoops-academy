package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.OptionalLong;

/** Append-only store of match events (bound tenant only). */
public interface MatchEventRepository {

    /** Every event of the match, in server order. */
    List<StoredEvent> findByMatch(MatchId matchId);

    /** Events with {@code serverSeq > after}, ascending, at most {@code limit}. */
    List<StoredEvent> after(MatchId matchId, long after, int limit);

    /** Highest server sequence number of the match, 0 without events. */
    long lastServerSeq(MatchId matchId);

    /**
     * Stores a new event and returns its server sequence number; empty when the id (or device sequence) is already
     * taken by another row, e.g. the same id in another match.
     */
    OptionalLong append(MatchId matchId, MatchEvent event, Recorder recorder);

    /** Sets {@code voided_by} from the latest projection (and clears it elsewhere). */
    void markVoided(MatchId matchId, Map<EventId, EventId> voidedBy);

    /** Remembers the highest client sequence seen per device (sync bookkeeping). */
    void recordReceipt(MatchId matchId, String deviceId, long clientSeq);

    long count();

    long countReceivedSince(Instant since);
}
