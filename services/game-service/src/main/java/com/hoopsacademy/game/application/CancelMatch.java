package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;

@ApplicationScoped
public class CancelMatch {

    private final MatchLookup lookup;
    private final MatchPermissions permissions;
    private final MatchRepository matches;
    private final Clock clock;

    CancelMatch(MatchLookup lookup, MatchPermissions permissions, MatchRepository matches, Clock clock) {
        this.lookup = lookup;
        this.permissions = permissions;
        this.matches = matches;
        this.clock = clock;
    }

    @Transactional
    public Match handle(MatchId id, String reason) {
        Match match = lookup.require(id);
        permissions.requireCanManage(match.teamId());
        match.cancel(reason, clock.instant());
        matches.save(match);
        return match;
    }
}
