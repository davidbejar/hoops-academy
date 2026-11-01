package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.projection.Projection;
import com.hoopsacademy.game.domain.projection.SeasonLine;
import java.util.List;
import java.util.Optional;

/** Persisted projections: match_player_stats and match_summary (bound tenant only). */
public interface ProjectionRepository {

    /** Replaces the stored projection of the match. */
    void save(MatchId matchId, Projection projection);

    /** The stored projection (without voidedBy), empty when the match was never projected. */
    Optional<Projection> find(MatchId matchId);

    /** The player's lines in LIVE and FINISHED matches of the season, by scheduled time. */
    List<SeasonLine> seasonLines(PlayerId playerId, SeasonId seasonId);
}
