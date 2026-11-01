package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.domain.eligibility.Eligibility;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * The eligibility-checked assignment command (ADMIN, or COACH of the team). INELIGIBLE → 422
 * {@code PLAYER_INELIGIBLE} with one violation per reason; PLAY_UP within the tenant limit is allowed. WP5 (approval of
 * ADD_PLAYER with a team) and case resolution (REASSIGNED) call this same command.
 */
@ApplicationScoped
public class AssignPlayerToTeam {

    public static final String INELIGIBLE = "PLAYER_INELIGIBLE";
    public static final String ALREADY_ON_TEAM = "PLAYER_ALREADY_ON_TEAM";
    public static final String JERSEY_TAKEN = "JERSEY_NUMBER_TAKEN";

    /** Contract {@code AssignPlayerRequest}; {@code joinedOn} defaults to today in the tenant's time zone. */
    public record Assignment(TeamId team, PlayerId player, Optional<JerseyNumber> jersey, Optional<LocalDate> joinedOn) {}

    private final TeamRepository teams;
    private final TeamPlayerRepository assignments;
    private final PlayerRepository players;
    private final EligibilityEngine engine;
    private final PlayerStatusSync statuses;
    private final TenantToday calendar;
    private final RosterAuthz authz;

    public AssignPlayerToTeam(TeamRepository teams, TeamPlayerRepository assignments, PlayerRepository players,
            EligibilityEngine engine, PlayerStatusSync statuses, TenantToday calendar, RosterAuthz authz) {
        this.teams = teams;
        this.assignments = assignments;
        this.players = players;
        this.engine = engine;
        this.statuses = statuses;
        this.calendar = calendar;
        this.authz = authz;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public TeamPlayerView assign(Assignment request) {
        Team team = teams.find(request.team()).orElseThrow(() -> new NotFoundException("Team not found"));
        authz.requireCoachOf(team.id());
        PlayerSummary player = players.summary(request.player())
                .orElseThrow(() -> new NotFoundException("Player not found"));
        if (assignments.findOpen(team.id(), player.id()).isPresent()) {
            throw new ConflictException("The player is already on the team", ALREADY_ON_TEAM);
        }
        request.jersey().filter(jersey -> assignments.jerseyTaken(team.id(), jersey, Optional.empty())).ifPresent(j -> {
            throw new ConflictException("Jersey " + j.value() + " is already used on the team", JERSEY_TAKEN);
        });
        LocalDate today = calendar.today();
        LocalDate joinedOn = request.joinedOn().orElse(today);
        Eligibility verdict = engine.evaluate(player, team, joinedOn).eligibility();
        if (!verdict.allowed()) {
            throw ineligible(verdict);
        }
        TeamPlayer assignment = TeamPlayer.assign(team.id(), player.id(), request.jersey().orElse(null), joinedOn,
                verdict.playUpLevels());
        assignments.insert(assignment);
        statuses.rederive(List.of(player.id()), today);
        return new TeamPlayerView(assignment, player.displayName(),
                players.summary(player.id()).orElseThrow().status());
    }

    static DomainRuleViolation ineligible(Eligibility verdict) {
        List<Problem.Violation> reasons = verdict.reasons().stream()
                .map(reason -> new Problem.Violation("playerId", reason.name(), "Ineligible: " + reason.name()))
                .toList();
        return new DomainRuleViolation("The player is not eligible for the team", INELIGIBLE, reasons);
    }
}
