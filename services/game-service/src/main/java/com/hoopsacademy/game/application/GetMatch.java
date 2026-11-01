package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

/** Any tenant member may read match metadata (see README: visibility decision). */
@ApplicationScoped
public class GetMatch {

    private final MatchLookup lookup;

    GetMatch(MatchLookup lookup) {
        this.lookup = lookup;
    }

    @Transactional
    public Match handle(MatchId id) {
        return lookup.require(id);
    }
}
