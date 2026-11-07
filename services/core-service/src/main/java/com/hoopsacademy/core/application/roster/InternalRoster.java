package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * {@code RosterPort} for game/athlete ({@code /internal/teams/{id}/roster}, {@code /internal/players:batch}): runs in
 * the tenant named by the caller; a missing or non-ACTIVE tenant answers 404, like the tenant filter would.
 */
@ApplicationScoped
public class InternalRoster {

    /** A roster line: open, valid assignment with the player's data. */
    public record RosterLine(PlayerSummary player, JerseyNumber jersey) {}

    /** Contract {@code TeamRoster}; {@code seasonEnd} is the last day of the team's season (ADR-0042). */
    public record TeamRosterView(TenantId tenant, Team team, LocalDate seasonEnd, List<RosterLine> players,
            List<TeamStaffMember> staff) {}

    private final TenantScope tenantScope;
    private final TenantProfileRepository profiles;
    private final TeamRepository teams;
    private final SeasonRepository seasons;
    private final TeamPlayerRepository assignments;
    private final TeamStaffRepository staff;
    private final PlayerRepository players;

    public InternalRoster(TenantScope tenantScope, TenantProfileRepository profiles, TeamRepository teams,
            SeasonRepository seasons, TeamPlayerRepository assignments, TeamStaffRepository staff,
            PlayerRepository players) {
        this.tenantScope = tenantScope;
        this.profiles = profiles;
        this.teams = teams;
        this.seasons = seasons;
        this.assignments = assignments;
        this.staff = staff;
        this.players = players;
    }

    public TeamRosterView teamRoster(TenantId tenant, TeamId teamId) {
        return tenantScope.runAs(tenant, () -> {
            requireActiveTenant();
            Team team = teams.find(teamId).orElseThrow(() -> new NotFoundException("Team not found"));
            List<TeamPlayer> open = assignments.openValidOfTeams(List.of(teamId));
            Map<PlayerId, PlayerSummary> summaries = players.summaries(open.stream().map(TeamPlayer::player).toList());
            List<RosterLine> lines = open.stream()
                    .map(assignment -> new RosterLine(summaries.get(assignment.player()), assignment.jersey()))
                    .filter(line -> hasBirthAndGender(line.player()))
                    .toList();
            LocalDate seasonEnd = seasons.find(team.season()).orElseThrow().endsOn();
            return new TeamRosterView(tenant, team, seasonEnd, lines, staff.ofTeam(teamId));
        });
    }

    /** Unknown ids (and records without birth date/gender, which the contract requires) are omitted. */
    public List<PlayerSummary> players(TenantId tenant, Collection<PlayerId> ids) {
        return tenantScope.runAs(tenant, () -> {
            requireActiveTenant();
            return players.summaries(ids).values().stream().filter(InternalRoster::hasBirthAndGender).toList();
        });
    }

    private void requireActiveTenant() {
        profiles.findCurrent().filter(profile -> profile.status() == TenantStatus.ACTIVE)
                .orElseThrow(() -> new NotFoundException("Tenant not found"));
    }

    private static boolean hasBirthAndGender(PlayerSummary player) {
        return player != null && Objects.nonNull(player.birthDate()) && Objects.nonNull(player.gender());
    }
}
