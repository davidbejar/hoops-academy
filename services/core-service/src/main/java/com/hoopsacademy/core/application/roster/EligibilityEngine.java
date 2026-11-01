package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.port.EligibilityCaseRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import com.hoopsacademy.core.domain.eligibility.CategoryLadder;
import com.hoopsacademy.core.domain.eligibility.Eligibility;
import com.hoopsacademy.core.domain.eligibility.EligibilityCase;
import com.hoopsacademy.core.domain.eligibility.EligibilityEvaluator;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.eligibility.Evaluation;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Applies the pure {@link EligibilityEvaluator} to the bound tenant's data. Re-evaluation looks at open, VALID
 * assignments only: an ineligible one is invalidated (never deleted), gets an OPEN case, and the player statuses are
 * re-derived. Invalidations are sticky until a person resolves the case, which makes every run idempotent.
 */
@ApplicationScoped
public class EligibilityEngine {

    private final SeasonRepository seasons;
    private final AgeCategoryRepository categories;
    private final TeamRepository teams;
    private final TeamPlayerRepository assignments;
    private final PlayerRepository players;
    private final EligibilityCaseRepository cases;
    private final TenantSettingsRepository settings;
    private final PlayerStatusSync statuses;
    private final TenantToday calendar;
    private final Clock clock;

    public EligibilityEngine(SeasonRepository seasons, AgeCategoryRepository categories, TeamRepository teams,
            TeamPlayerRepository assignments, PlayerRepository players, EligibilityCaseRepository cases,
            TenantSettingsRepository settings, PlayerStatusSync statuses, TenantToday calendar, Clock clock) {
        this.seasons = seasons;
        this.categories = categories;
        this.teams = teams;
        this.assignments = assignments;
        this.players = players;
        this.cases = cases;
        this.settings = settings;
        this.statuses = statuses;
        this.calendar = calendar;
        this.clock = clock;
    }

    public EligibilityEvaluator evaluator() {
        return evaluator(currentSettings());
    }

    /** Side-effect free verdict for one player and one team. */
    public Evaluation evaluate(PlayerSummary player, Team team, LocalDate asOf) {
        return evaluator().evaluate(player.candidate(), team, season(team.season()), asOf);
    }

    /** Every current and upcoming season of the tenant, as of {@code today}, under {@code rules}. */
    public List<EligibilityCase> reevaluateTenant(LocalDate today, TenantSettings rules) {
        List<SeasonId> live = seasons.notEndedOn(today).stream().map(Season::id).toList();
        return reevaluate(teams.inSeasons(live), today, rules);
    }

    public List<EligibilityCase> reevaluateTenant() {
        return reevaluateTenant(calendar.today(), currentSettings());
    }

    public List<EligibilityCase> reevaluateSeason(SeasonId season) {
        return reevaluate(teams.inSeasons(List.of(season)), calendar.today(), currentSettings());
    }

    public List<EligibilityCase> reevaluateTeam(Team team) {
        return reevaluate(List.of(team), calendar.today(), currentSettings());
    }

    /** Invalidates {@code assignment} for {@code reason} and opens its case. */
    public EligibilityCase invalidate(TeamPlayer assignment, EligibilityReason reason) {
        Instant now = clock.instant();
        assignments.update(assignment.invalidate(reason, now));
        EligibilityCase opened = EligibilityCase.open(assignment.player(), assignment.id(), reason, now);
        cases.insert(opened);
        return opened;
    }

    private List<EligibilityCase> reevaluate(Collection<Team> scope, LocalDate asOf, TenantSettings rules) {
        if (scope.isEmpty()) {
            return List.of();
        }
        EligibilityEvaluator evaluator = evaluator(rules);
        Map<TeamId, Team> teamsById = scope.stream().collect(Collectors.toMap(Team::id, Function.identity()));
        Map<SeasonId, Season> seasonsById = new HashMap<>();
        List<TeamPlayer> open = assignments.openValidOfTeams(teamsById.keySet());
        Map<PlayerId, PlayerSummary> summaries = players.summaries(open.stream().map(TeamPlayer::player).toList());
        List<EligibilityCase> opened = new ArrayList<>();
        for (TeamPlayer assignment : open) {
            Team team = teamsById.get(assignment.team());
            Season season = seasonsById.computeIfAbsent(team.season(), this::season);
            Eligibility verdict = evaluator.evaluate(summaries.get(assignment.player()).candidate(), team, season, asOf)
                    .eligibility();
            if (verdict instanceof Eligibility.Ineligible ineligible) {
                opened.add(invalidate(assignment, ineligible.primaryReason()));
            }
        }
        statuses.rederive(summaries.keySet(), asOf);
        return opened;
    }

    private EligibilityEvaluator evaluator(TenantSettings rules) {
        return new EligibilityEvaluator(CategoryLadder.of(categories.listByRank()), rules);
    }

    private TenantSettings currentSettings() {
        return settings.findCurrent().orElseThrow(() -> new NotFoundException("Tenant settings not found"));
    }

    private Season season(SeasonId id) {
        return seasons.find(id).orElseThrow(() -> new NotFoundException("Season not found"));
    }
}
