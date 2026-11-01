package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Instant;

/** Schedules a match for a team; the season is the one core reports for the team. */
@ApplicationScoped
public class CreateMatch {

    private final MatchPermissions permissions;
    private final RosterPort rosterPort;
    private final MatchRepository matches;
    private final CurrentCaller caller;

    public CreateMatch(MatchPermissions permissions, RosterPort rosterPort, MatchRepository matches, CurrentCaller caller) {
        this.permissions = permissions;
        this.rosterPort = rosterPort;
        this.matches = matches;
        this.caller = caller;
    }

    public record Command(
            TeamId teamId, String opponentName, HomeAway homeAway, Instant scheduledAt, String venue,
            Integer periodCount, Integer periodMinutes) {}

    @Transactional
    public Match handle(Command command) {
        permissions.requireCanManage(command.teamId());
        TeamRoster team = rosterPort.teamRoster(caller.tenantId(), command.teamId());
        Match match = Match.schedule(
                MatchId.random(), command.teamId(), team.seasonId(), command.opponentName(), command.homeAway(),
                command.scheduledAt(), command.venue(), command.periodCount(), command.periodMinutes(), caller.personId());
        matches.save(match);
        return match;
    }
}
