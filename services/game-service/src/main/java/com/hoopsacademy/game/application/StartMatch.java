package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;

/** SCHEDULED to LIVE; needs a roster with at least one starter. */
@ApplicationScoped
public class StartMatch {

    private final MatchLookup lookup;
    private final MatchPermissions permissions;
    private final MatchRepository matches;
    private final Clock clock;

    StartMatch(MatchLookup lookup, MatchPermissions permissions, MatchRepository matches, Clock clock) {
        this.lookup = lookup;
        this.permissions = permissions;
        this.matches = matches;
        this.clock = clock;
    }

    @Transactional
    public Match handle(MatchId id) {
        Match match = lookup.require(id);
        permissions.requireCanManage(match.teamId());
        match.start(matches.roster(id), clock.instant());
        matches.save(match);
        return match;
    }
}
