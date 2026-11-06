package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Instant;

@ApplicationScoped
public class UpdateMatch {

    private final MatchLookup lookup;
    private final MatchPermissions permissions;
    private final MatchRepository matches;
    private final MatchReprojection reprojection;

    UpdateMatch(MatchLookup lookup, MatchPermissions permissions, MatchRepository matches, MatchReprojection reprojection) {
        this.lookup = lookup;
        this.permissions = permissions;
        this.matches = matches;
        this.reprojection = reprojection;
    }

    /** @param venueGiven true when the venue is set or cleared (ADR-0032: then venue null clears it) */
    public record Command(
            String opponentName, HomeAway homeAway, Instant scheduledAt, boolean venueGiven, String venue,
            Integer periodCount, Integer periodMinutes) {}

    @Transactional
    public Match handle(MatchId id, Command command) {
        Match match = lookup.require(id);
        permissions.requireCanManage(match.teamId());
        match.update(command.opponentName(), command.homeAway(), command.scheduledAt(), command.venueGiven(),
                command.venue(), command.periodCount(), command.periodMinutes());
        matches.save(match);
        if (command.periodCount() != null || command.periodMinutes() != null) {
            reprojection.reproject(match); // minutes depend on the period lengths
        }
        return match;
    }
}
