package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import java.util.Optional;

/** Persistence port of the match aggregate and its roster; always scoped to the bound tenant. */
public interface MatchRepository {

    void save(Match match);

    Optional<Match> findById(MatchId id);

    /**
     * Loads the match and locks its row until the transaction ends (serialises event ingest per match). Its score is
     * not read ({@link com.hoopsacademy.game.domain.MatchScore#NONE}): ingest re-projects it.
     */
    Optional<Match> lockById(MatchId id);

    MatchPage list(MatchFilter filter, int page, int size);

    MatchRoster roster(MatchId id);

    void replaceRoster(MatchRoster roster);
}
