package com.hoopsacademy.game.application;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;

/** Loads a match of the bound tenant; RLS hides other tenants' matches, so they are simply "not found". */
@ApplicationScoped
class MatchLookup {

    private final MatchRepository matches;

    MatchLookup(MatchRepository matches) {
        this.matches = matches;
    }

    Match require(MatchId id) {
        return matches.findById(id).orElseThrow(() -> new NotFoundException("Match " + id + " not found"));
    }
}
