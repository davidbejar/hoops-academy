package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.EligibilityCaseRepository;
import com.hoopsacademy.core.application.port.EligibilityCaseRepository.CaseFilter;
import com.hoopsacademy.core.application.port.EligibilityCaseRepository.CaseOfTeam;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.eligibility.CaseResolution;
import com.hoopsacademy.core.domain.eligibility.CaseStatus;
import com.hoopsacademy.core.domain.eligibility.EligibilityCase;
import com.hoopsacademy.core.domain.eligibility.EligibilityCaseId;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Eligibility cases: ADMIN sees all, team staff see their teams' cases; ADMIN or the team's COACH resolves. */
@ApplicationScoped
public class EligibilityCaseService {

    public static final String TARGET_REQUIRED = "TARGET_TEAM_REQUIRED";

    /** Contract query of {@code listEligibilityCases}. */
    public record CaseQuery(Optional<CaseStatus> status, Optional<TeamId> team, Optional<PlayerId> player) {}

    /** Contract {@code ResolveEligibilityCaseRequest}. */
    public record Resolution(CaseResolution resolution, Optional<TeamId> targetTeam, String note) {}

    /** A case with the names the contract shows. */
    public record CaseView(EligibilityCase eligibilityCase, TeamId team, String teamName, String playerName,
            String resolverName) {}

    private final EligibilityCaseRepository cases;
    private final TeamRepository teams;
    private final TeamPlayerRepository assignments;
    private final PlayerRepository players;
    private final PersonRepository persons;
    private final AssignPlayerToTeam assign;
    private final PlayerStatusSync statuses;
    private final TenantToday calendar;
    private final RosterAuthz authz;
    private final Clock clock;

    public EligibilityCaseService(EligibilityCaseRepository cases, TeamRepository teams,
            TeamPlayerRepository assignments, PlayerRepository players, PersonRepository persons,
            AssignPlayerToTeam assign, PlayerStatusSync statuses, TenantToday calendar, RosterAuthz authz, Clock clock) {
        this.cases = cases;
        this.teams = teams;
        this.assignments = assignments;
        this.players = players;
        this.persons = persons;
        this.assign = assign;
        this.statuses = statuses;
        this.calendar = calendar;
        this.authz = authz;
        this.clock = clock;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH})
    public PageResult<CaseView> list(CaseQuery query, PageRequest page) {
        Optional<Set<TeamId>> onlyTeams = authz.isAdmin() ? Optional.empty()
                : Optional.of(authz.staffTeams().stream().map(TeamId::new).collect(Collectors.toSet()));
        PageResult<CaseOfTeam> found = cases.list(
                new CaseFilter(query.status(), query.team(), query.player(), onlyTeams), page);
        return new PageResult<>(views(found.items()), page, found.totalElements());
    }

    @Transactional
    public CaseView get(EligibilityCaseId id) {
        CaseOfTeam found = find(id);
        authz.requireStaffOf(found.team());
        return views(List.of(found)).get(0);
    }

    /**
     * REASSIGNED runs the eligibility-checked assignment to the target team (422 when ineligible, the case stays
     * OPEN) and closes the invalid assignment; REMOVED_FROM_TEAM closes it; DISMISSED records the decision only.
     */
    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public CaseView resolve(EligibilityCaseId id, Resolution resolution) {
        CaseOfTeam found = find(id);
        authz.requireCoachOf(found.team());
        EligibilityCase open = found.eligibilityCase();
        EligibilityCase resolved = open.resolve(resolution.resolution(), authz.callerPerson(), resolution.note(),
                clock.instant());
        switch (resolution.resolution()) {
            case REASSIGNED -> {
                TeamId target = resolution.targetTeam().orElseThrow(() -> new DomainRuleViolation(
                        "REASSIGNED requires targetTeamId", TARGET_REQUIRED));
                assign.assign(new AssignPlayerToTeam.Assignment(target, open.player(), Optional.empty(), Optional.empty()));
                closeInvalidAssignment(open);
            }
            case REMOVED_FROM_TEAM -> closeInvalidAssignment(open);
            case DISMISSED -> { }
        }
        cases.update(resolved);
        statuses.rederive(List.of(open.player()), calendar.today());
        return views(List.of(new CaseOfTeam(resolved, found.team()))).get(0);
    }

    private void closeInvalidAssignment(EligibilityCase open) {
        assignments.find(open.assignment()).filter(TeamPlayer::isOpen)
                .ifPresent(assignment -> assignments.update(assignment.close(calendar.today())));
    }

    private CaseOfTeam find(EligibilityCaseId id) {
        return cases.find(id).orElseThrow(() -> new NotFoundException("Eligibility case not found"));
    }

    private List<CaseView> views(List<CaseOfTeam> found) {
        Map<TeamId, Team> teamsById = teams.findAll(found.stream().map(CaseOfTeam::team).distinct().toList()).stream()
                .collect(Collectors.toMap(Team::id, Function.identity()));
        Map<PlayerId, PlayerSummary> playersById = players.summaries(
                found.stream().map(c -> c.eligibilityCase().player()).toList());
        Map<PersonId, String> resolvers = persons.findAll(found.stream().map(c -> c.eligibilityCase().resolvedBy())
                        .filter(Objects::nonNull).distinct().toList()).stream()
                .collect(Collectors.toMap(Person::id, Person::displayName));
        return found.stream().map(c -> new CaseView(c.eligibilityCase(), c.team(), teamsById.get(c.team()).name(),
                playersById.get(c.eligibilityCase().player()).displayName(),
                c.eligibilityCase().resolvedBy() == null ? null
                        : resolvers.getOrDefault(c.eligibilityCase().resolvedBy(), ""))).toList();
    }
}
