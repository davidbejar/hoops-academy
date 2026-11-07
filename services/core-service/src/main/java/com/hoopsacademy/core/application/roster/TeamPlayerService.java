package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.shared.Patch;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * A team's assignments: any member lists them; ADMIN or the team's COACH renumbers and unassigns, never once the
 * team's season has ended (409 {@code SEASON_ENDED}, ADR-0042).
 */
@ApplicationScoped
public class TeamPlayerService {

    private final TeamRepository teams;
    private final TeamPlayerRepository assignments;
    private final PlayerRepository players;
    private final PlayerStatusSync statuses;
    private final TenantToday calendar;
    private final PastSeasons pastSeasons;

    public TeamPlayerService(TeamRepository teams, TeamPlayerRepository assignments, PlayerRepository players,
            PlayerStatusSync statuses, TenantToday calendar, PastSeasons pastSeasons) {
        this.teams = teams;
        this.assignments = assignments;
        this.players = players;
        this.statuses = statuses;
        this.calendar = calendar;
        this.pastSeasons = pastSeasons;
    }

    @Transactional
    public List<TeamPlayerView> list(TeamId team, boolean includeLeft) {
        requireTeam(team);
        List<TeamPlayer> found = assignments.ofTeam(team, includeLeft);
        Map<PlayerId, PlayerSummary> summaries = players.summaries(found.stream().map(TeamPlayer::player).toList());
        return found.stream().map(a -> view(a, summaries.get(a.player()))).toList();
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public TeamPlayerView renumber(TeamId team, PlayerId player, Patch<JerseyNumber> change) {
        TeamPlayer open = openAssignment(team, player);
        JerseyNumber jersey = change.applyTo(open.jersey());
        if (jersey != null && assignments.jerseyTaken(team, jersey, Optional.of(open.id()))) {
            throw new ConflictException("Jersey " + jersey.value() + " is already used on the team",
                    AssignPlayerToTeam.JERSEY_TAKEN);
        }
        TeamPlayer renumbered = open.withJersey(jersey);
        if (!renumbered.equals(open)) {
            assignments.update(renumbered);
        }
        return view(renumbered, players.summary(player).orElseThrow());
    }

    /** Closes the open assignment (history is kept); the player may become ORPHAN. */
    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public void unassign(TeamId team, PlayerId player) {
        TeamPlayer open = openAssignment(team, player);
        assignments.update(open.close(calendar.today()));
        statuses.rederive(List.of(player), calendar.today());
    }

    private TeamPlayer openAssignment(TeamId team, PlayerId player) {
        pastSeasons.requireOpenForCoach(requireTeam(team));
        return assignments.findOpen(team, player).orElseThrow(() -> new NotFoundException("No open assignment"));
    }

    private Team requireTeam(TeamId team) {
        return teams.find(team).orElseThrow(() -> new NotFoundException("Team not found"));
    }

    private static TeamPlayerView view(TeamPlayer assignment, PlayerSummary player) {
        return new TeamPlayerView(assignment, player.displayName(), player.status());
    }
}
