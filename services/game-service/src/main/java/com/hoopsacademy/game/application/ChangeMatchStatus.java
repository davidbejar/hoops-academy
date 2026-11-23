package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.function.Consumer;

/**
 * The lifecycle transitions of a match (contract startMatch, finishMatch, cancelMatch): ADMIN or staff of the team
 * whose season has not ended; the domain decides whether the transition is legal.
 */
@ApplicationScoped
public class ChangeMatchStatus {

    private final MatchLookup lookup;
    private final MatchPermissions permissions;
    private final MatchRepository matches;
    private final Clock clock;

    ChangeMatchStatus(MatchLookup lookup, MatchPermissions permissions, MatchRepository matches, Clock clock) {
        this.lookup = lookup;
        this.permissions = permissions;
        this.matches = matches;
        this.clock = clock;
    }

    /** SCHEDULED to LIVE; needs a roster with at least one starter. */
    @Transactional
    public Match start(MatchId id) {
        return transition(id, match -> match.start(matches.roster(id), clock.instant()));
    }

    @Transactional
    public Match finish(MatchId id) {
        return transition(id, match -> match.finish(clock.instant()));
    }

    @Transactional
    public Match cancel(MatchId id, String reason) {
        return transition(id, match -> match.cancel(reason, clock.instant()));
    }

    private Match transition(MatchId id, Consumer<Match> change) {
        Match match = lookup.require(id);
        permissions.requireCanManage(match.teamId());
        change.accept(match);
        matches.save(match);
        return match;
    }
}
