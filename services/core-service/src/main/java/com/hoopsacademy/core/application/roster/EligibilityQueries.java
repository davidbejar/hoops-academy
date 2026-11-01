package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.domain.eligibility.EligibilityEvaluator;
import com.hoopsacademy.core.domain.eligibility.Evaluation;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/** Side-effect free eligibility reads: one player × one team, and the teams of a season a player may join. */
@ApplicationScoped
public class EligibilityQueries {

    /** Contract {@code EligibilityCheck}. */
    public record CheckView(PlayerId player, TeamId team, LocalDate asOf, Evaluation evaluation) {}

    /** Contract {@code EligibleTeam}. */
    public record EligibleTeamView(TeamView team, CheckView check) {}

    private final TeamRepository teams;
    private final SeasonRepository seasons;
    private final PlayerRepository players;
    private final EligibilityEngine engine;
    private final TeamViews views;
    private final TenantToday calendar;
    private final RosterAuthz authz;

    public EligibilityQueries(TeamRepository teams, SeasonRepository seasons, PlayerRepository players,
            EligibilityEngine engine, TeamViews views, TenantToday calendar, RosterAuthz authz) {
        this.teams = teams;
        this.seasons = seasons;
        this.players = players;
        this.engine = engine;
        this.views = views;
        this.calendar = calendar;
        this.authz = authz;
    }

    /** ADMIN or team staff; {@code asOf} defaults to today in the tenant's time zone. */
    @Transactional
    public CheckView check(TeamId teamId, PlayerId playerId, Optional<LocalDate> asOf) {
        Team team = teams.find(teamId).orElseThrow(() -> new NotFoundException("Team not found"));
        authz.requireStaffOf(teamId);
        PlayerSummary player = player(playerId);
        LocalDate date = asOf.orElseGet(calendar::today);
        return new CheckView(playerId, teamId, date, engine.evaluate(player, team, date));
    }

    /** ELIGIBLE and PLAY_UP teams of {@code seasonId}, by category rank then name (feeds the assignment UI). */
    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public List<EligibleTeamView> eligibleTeams(PlayerId playerId, SeasonId seasonId) {
        PlayerSummary player = player(playerId);
        Season season = seasons.find(seasonId).orElseThrow(() -> new NotFoundException("Season not found"));
        LocalDate today = calendar.today();
        EligibilityEvaluator evaluator = engine.evaluator();
        return views.of(teams.inSeasons(List.of(seasonId))).stream()
                .map(view -> new EligibleTeamView(view, new CheckView(playerId, view.team().id(), today,
                        evaluator.evaluate(player.candidate(), view.team(), season, today))))
                .filter(eligible -> eligible.check().evaluation().eligibility().allowed())
                .sorted(Comparator.comparingInt((EligibleTeamView e) -> e.team().category().rank())
                        .thenComparing(e -> e.team().team().name()))
                .toList();
    }

    private PlayerSummary player(PlayerId id) {
        return players.summary(id).orElseThrow(() -> new NotFoundException("Player not found"));
    }
}
