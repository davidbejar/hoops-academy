package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;

@ApplicationScoped
public class FinishMatch {

    private final MatchLookup lookup;
    private final MatchPermissions permissions;
    private final MatchRepository matches;
    private final Clock clock;

    FinishMatch(MatchLookup lookup, MatchPermissions permissions, MatchRepository matches, Clock clock) {
        this.lookup = lookup;
        this.permissions = permissions;
        this.matches = matches;
        this.clock = clock;
    }

    @Transactional
    public Match handle(MatchId id) {
        Match match = lookup.require(id);
        permissions.requireCanManage(match.teamId());
        match.finish(clock.instant());
        matches.save(match);
        return match;
    }
}
