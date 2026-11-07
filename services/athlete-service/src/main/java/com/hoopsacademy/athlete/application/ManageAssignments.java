package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.application.AssignmentRepository.AssignmentQuery;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.AssignmentId;
import com.hoopsacademy.athlete.domain.PlanAssignment;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TrainingPlan;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Assigning plans to teams or players and reading the assignments (team assignments fan out to the roster at read time). */
@ApplicationScoped
public class ManageAssignments {

    public record NewAssignment(PlanId planId, Optional<TeamId> team, Optional<PlayerId> player, LocalDate dueOn,
            String notes) {}

    public record Filter(Optional<TeamId> team, Optional<PlayerId> player, Optional<LocalDate> dueFrom,
            Optional<LocalDate> dueTo, int page, int size) {}

    /** An assignment with the plan it points to. */
    public record AssignmentView(PlanAssignment assignment, TrainingPlan plan) {}

    private final AssignmentRepository assignments;
    private final PlanRepository plans;
    private final PlanAccess access;
    private final TenantClock clock;

    public ManageAssignments(AssignmentRepository assignments, PlanRepository plans, PlanAccess access, TenantClock clock) {
        this.assignments = assignments;
        this.plans = plans;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public AssignmentView create(AuthzContext caller, Actor actor, NewAssignment request) {
        access.requireStaffRole(caller);
        PlanAssignment assignment = PlanAssignment.create(request.planId(), request.team(), request.player(),
                request.dueOn(), request.notes(), actor, clock.now());
        TrainingPlan plan = plans.find(request.planId()).orElseThrow(() -> new NotFoundException("Plan not found"));
        if (plan.template()) {
            throw new DomainRuleViolation("Copy the template into a plan of your own before assigning it", "PLAN_IS_TEMPLATE");
        }
        if (plan.archived()) {
            throw new DomainRuleViolation("An archived plan cannot be assigned", "PLAN_ARCHIVED");
        }
        if (plan.session().isPresent()) {
            throw new DomainRuleViolation("The plan of a session cannot be assigned; copy it first", "PLAN_OF_A_SESSION");
        }
        access.requireMayAssign(caller, assignment);
        assignments.save(assignment);
        return new AssignmentView(assignment, plan);
    }

    @Transactional
    public AssignmentView get(AuthzContext caller, AssignmentId id) {
        PlanAssignment assignment = load(id);
        access.requireView(caller, assignment);
        return view(assignment);
    }

    @Transactional
    public void delete(AuthzContext caller, AssignmentId id) {
        access.requireStaffRole(caller);
        PlanAssignment assignment = load(id);
        access.requireMayWithdraw(caller, assignment);
        assignments.delete(id);
    }

    @Transactional
    public PageResult<AssignmentView> list(AuthzContext caller, Filter filter) {
        Scope scope = scopeOf(caller, filter);
        PageResult<PlanAssignment> found = assignments.search(new AssignmentQuery(scope.teams(), scope.players(),
                filter.dueFrom(), filter.dueTo(), filter.page(), filter.size()));
        Map<PlanId, TrainingPlan> byId = plans.findAll(found.items().stream().map(PlanAssignment::planId).distinct().toList())
                .stream().collect(Collectors.toMap(TrainingPlan::id, Function.identity()));
        return found.map(a -> new AssignmentView(a, byId.get(a.planId())));
    }

    /** Teams and players an assignment may be addressed to for this caller and filter; {@code null} = unrestricted. */
    private record Scope(Collection<TeamId> teams, Collection<PlayerId> players) {}

    private Scope scopeOf(AuthzContext caller, Filter filter) {
        boolean staff = access.isStaff(caller);
        Set<PlayerId> related = access.relatedPlayers(caller);
        filter.player().filter(p -> !staff && !related.contains(p)).ifPresent(p -> {
            throw new AccessDeniedException("Not allowed to see the assignments of this player");
        });
        if (filter.team().isPresent() && !staff) {
            access.teamRoster(caller.tenantId(), filter.team().get()).filter(r -> related.stream().anyMatch(r::hasPlayer))
                    .orElseThrow(() -> new NotFoundException("Team not found"));
        }
        if (filter.player().isPresent()) {
            return forPlayers(caller, Set.of(filter.player().get()), filter.team());
        }
        if (filter.team().isPresent()) {
            return new Scope(List.of(filter.team().get()), List.of());
        }
        return staff ? new Scope(null, null) : forPlayers(caller, related, Optional.empty());
    }

    private Scope forPlayers(AuthzContext caller, Set<PlayerId> players, Optional<TeamId> onlyTeam) {
        List<TeamId> candidates = assignments.teamsWithAssignments().stream()
                .filter(team -> onlyTeam.map(team::equals).orElse(true)).toList();
        Set<TeamId> teams = new LinkedHashSet<>();
        players.forEach(player -> teams.addAll(access.teamsOf(caller.tenantId(), player, candidates)));
        return new Scope(new ArrayList<>(teams), players);
    }

    private PlanAssignment load(AssignmentId id) {
        return assignments.find(id).orElseThrow(() -> new NotFoundException("Assignment not found"));
    }

    private AssignmentView view(PlanAssignment assignment) {
        return new AssignmentView(assignment, plans.find(assignment.planId())
                .orElseThrow(() -> new NotFoundException("Plan not found")));
    }
}
