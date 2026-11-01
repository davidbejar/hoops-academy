package com.hoopsacademy.game.application;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;

/**
 * Replaces the roster of an open match. Every player must be on the team's current roster in core; names and jerseys
 * are copied into the match so offline sync never depends on core. The contract has no guest flag, so a player outside
 * the team is rejected with PLAYER_NOT_IN_TEAM (422).
 */
@ApplicationScoped
public class ReplaceMatchRoster {

    private final MatchLookup lookup;
    private final MatchPermissions permissions;
    private final RosterPort rosterPort;
    private final MatchRepository matches;
    private final CurrentCaller caller;

    ReplaceMatchRoster(
            MatchLookup lookup, MatchPermissions permissions, RosterPort rosterPort, MatchRepository matches,
            CurrentCaller caller) {
        this.lookup = lookup;
        this.permissions = permissions;
        this.rosterPort = rosterPort;
        this.matches = matches;
        this.caller = caller;
    }

    /** @param jerseyNumber overrides the team jersey for this match, null keeps the team's */
    public record Entry(PlayerId playerId, String jerseyNumber, boolean starter) {}

    @Transactional
    public MatchRoster handle(MatchId id, List<Entry> requested) {
        Match match = lookup.require(id);
        permissions.requireCanManage(match.teamId());
        match.requireRosterEditable();
        TeamRoster team = rosterPort.teamRoster(caller.tenantId(), match.teamId());
        List<Problem.Violation> outsiders = requested.stream()
                .filter(entry -> team.find(entry.playerId()).isEmpty())
                .map(entry -> new Problem.Violation("entries", "PLAYER_NOT_IN_TEAM",
                        "Player " + entry.playerId() + " is not on the team"))
                .toList();
        if (!outsiders.isEmpty()) {
            throw new DomainRuleViolation("Some players are not on the team", "PLAYER_NOT_IN_TEAM", outsiders);
        }
        List<RosterEntry> entries = requested.stream().map(entry -> snapshot(team, entry)).toList();
        MatchRoster roster = new MatchRoster(id, entries);
        matches.replaceRoster(roster);
        return roster;
    }

    private static RosterEntry snapshot(TeamRoster team, Entry entry) {
        TeamRoster.Player player = team.find(entry.playerId()).orElseThrow();
        String jersey = entry.jerseyNumber() != null ? entry.jerseyNumber() : player.jerseyNumber();
        return new RosterEntry(entry.playerId(), player.displayName(), JerseyNumber.ofNullable(jersey), entry.starter());
    }
}
