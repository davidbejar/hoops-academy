package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.port.EntitlementService;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamRepository.TeamFilter;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamChanges;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Teams: any member reads, ADMIN writes; names are unique per season (409 {@code TEAM_NAME_TAKEN}); a team of an ended
 * season is read-only (409 {@code SEASON_ENDED}, ADR-0042).
 */
@ApplicationScoped
public class TeamService {

    public static final String NAME_TAKEN = "TEAM_NAME_TAKEN";

    /** Contract {@code CreateTeamRequest}. */
    public record NewTeam(SeasonId season, String name, String alias, AgeCategoryId category, GenderPolicy genderPolicy) {}

    /**
     * Contract query of {@code listTeams}; {@code includeEnded} adds the caller's historic staff teams to
     * {@code staffedByMe} (ADR-0042).
     */
    public record TeamQuery(Optional<SeasonId> season, Optional<AgeCategoryId> category, boolean staffedByMe,
            boolean includeEnded) {}

    private final TenantContext tenantContext;
    private final TeamRepository teams;
    private final SeasonRepository seasons;
    private final AgeCategoryRepository categories;
    private final EntitlementService entitlements;
    private final EligibilityEngine engine;
    private final TeamViews views;
    private final RosterAuthz authz;
    private final PastSeasons pastSeasons;

    public TeamService(TenantContext tenantContext, TeamRepository teams, SeasonRepository seasons,
            AgeCategoryRepository categories, EntitlementService entitlements, EligibilityEngine engine, TeamViews views,
            RosterAuthz authz, PastSeasons pastSeasons) {
        this.tenantContext = tenantContext;
        this.teams = teams;
        this.seasons = seasons;
        this.categories = categories;
        this.entitlements = entitlements;
        this.engine = engine;
        this.views = views;
        this.authz = authz;
        this.pastSeasons = pastSeasons;
    }

    @Transactional
    public PageResult<TeamView> list(TeamQuery query, PageRequest page) {
        Optional<Set<TeamId>> onlyTeams = query.staffedByMe()
                ? Optional.of(staffedByCaller(query.includeEnded()))
                : Optional.empty();
        PageResult<Team> found = teams.list(new TeamFilter(query.season(), query.category(), onlyTeams), page);
        return new PageResult<>(views.of(found.items()), page, found.totalElements());
    }

    @Transactional
    public TeamView get(TeamId id) {
        return views.of(find(id));
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public TeamView create(NewTeam input) {
        Team team = new Team(TeamId.random(), input.season(), input.name(), input.alias(), input.category(),
                input.genderPolicy());
        seasons.find(team.season()).orElseThrow(() -> new NotFoundException("Season not found"));
        requireCategory(team.category());
        requireUniqueName(team);
        entitlements.check(tenantContext.requireTenantId(), EntitlementService.Limit.TEAMS);
        teams.insert(team);
        return views.of(team);
    }

    /** A new category or gender policy re-evaluates the team's open assignments. */
    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public TeamView update(TeamId id, TeamChanges changes) {
        Team before = find(id);
        pastSeasons.requireOpenForAdmin(before);
        Team after = before.apply(changes);
        requireCategory(after.category());
        requireUniqueName(after);
        if (after.equals(before)) {
            return views.of(before);
        }
        teams.update(after);
        if (changes.changesEligibility()) {
            engine.reevaluateTeam(after);
        }
        return views.of(after);
    }

    private Set<TeamId> staffedByCaller(boolean includeEnded) {
        Set<TeamId> staffed = authz.staffTeams().stream().map(TeamId::new).collect(Collectors.toSet());
        if (includeEnded) {
            authz.historicStaffTeams().forEach(id -> staffed.add(new TeamId(id)));
        }
        return staffed;
    }

    Team find(TeamId id) {
        return teams.find(id).orElseThrow(() -> new NotFoundException("Team not found"));
    }

    private void requireCategory(AgeCategoryId category) {
        categories.find(category).orElseThrow(() -> new NotFoundException("Age category not found"));
    }

    private void requireUniqueName(Team team) {
        if (teams.nameTaken(team.season(), team.name(), Optional.of(team.id()))) {
            throw new ConflictException("A team with this name exists in the season", NAME_TAKEN);
        }
    }
}
