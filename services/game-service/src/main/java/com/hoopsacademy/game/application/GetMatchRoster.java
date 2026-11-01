package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

@ApplicationScoped
public class GetMatchRoster {

    private final MatchLookup lookup;
    private final MatchRepository matches;

    GetMatchRoster(MatchLookup lookup, MatchRepository matches) {
        this.lookup = lookup;
        this.matches = matches;
    }

    @Transactional
    public MatchRoster handle(MatchId id) {
        lookup.require(id);
        return matches.roster(id);
    }
}
