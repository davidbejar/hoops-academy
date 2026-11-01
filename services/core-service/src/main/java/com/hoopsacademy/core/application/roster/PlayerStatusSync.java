package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.domain.eligibility.PlayerStatusDerivation;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Keeps {@code player.status} consistent with the assignments (ADR-0014): an ACTIVE player without a valid open
 * assignment to a team of a current or upcoming season is ORPHAN, and back. Idempotent.
 */
@ApplicationScoped
public class PlayerStatusSync {

    private final SeasonRepository seasons;
    private final TeamRepository teams;
    private final TeamPlayerRepository assignments;
    private final PlayerRepository players;

    public PlayerStatusSync(SeasonRepository seasons, TeamRepository teams, TeamPlayerRepository assignments,
            PlayerRepository players) {
        this.seasons = seasons;
        this.teams = teams;
        this.assignments = assignments;
        this.players = players;
    }

    public void rederive(Collection<PlayerId> ids, LocalDate today) {
        if (ids.isEmpty()) {
            return;
        }
        Set<TeamId> liveTeams = teams.inSeasons(seasons.notEndedOn(today).stream().map(Season::id).toList()).stream()
                .map(Team::id).collect(Collectors.toSet());
        Set<PlayerId> placed = assignments.openOfPlayers(ids).stream()
                .filter(TeamPlayer::isValid)
                .filter(assignment -> liveTeams.contains(assignment.team()))
                .map(TeamPlayer::player).collect(Collectors.toSet());
        for (PlayerSummary player : players.summaries(ids).values()) {
            PlayerStatus next = PlayerStatusDerivation.derive(player.status(), placed.contains(player.id()));
            if (next != player.status()) {
                players.updateStatus(player.id(), next);
            }
        }
    }
}
