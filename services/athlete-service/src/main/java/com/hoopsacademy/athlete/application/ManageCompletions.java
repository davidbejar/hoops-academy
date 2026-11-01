package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.application.AssignmentRepository.CompletionQuery;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.AssignmentId;
import com.hoopsacademy.athlete.domain.CompletionStatus;
import com.hoopsacademy.athlete.domain.PlanAssignment;
import com.hoopsacademy.athlete.domain.PlanCompletion;
import com.hoopsacademy.athlete.domain.PlanProgress;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/** Marking plan completions (player self, linked parent, staff of the team, ADMIN), listing them and per-assignment progress. */
@ApplicationScoped
public class ManageCompletions {

    private final AssignmentRepository assignments;
    private final PlanAccess access;
    private final TenantClock clock;

    public ManageCompletions(AssignmentRepository assignments, PlanAccess access, TenantClock clock) {
        this.assignments = assignments;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public PlanCompletion record(AuthzContext caller, Actor actor, AssignmentId assignmentId, PlayerId player,
            CompletionStatus status, String note) {
        PlanAssignment assignment = load(assignmentId);
        access.requireView(caller, assignment);
        if (!access.mayMark(caller, assignment, player)) {
            throw new AccessDeniedException("Not allowed to mark this player's completion");
        }
        if (!targetsOf(caller, assignment).contains(player)) {
            throw assignment.teamId().isPresent()
                    ? new DomainRuleViolation("The player is not in the assigned team", "PLAYER_NOT_IN_TEAM")
                    : new DomainRuleViolation("The assignment is for another player", "PLAYER_NOT_TARGETED");
        }
        PlanCompletion completion = assignments.findCompletion(assignmentId, player)
                .map(existing -> existing.changedTo(status, note, actor, clock.now()))
                .orElseGet(() -> PlanCompletion.record(assignmentId, player, status, note, actor, clock.now()));
        assignments.saveCompletion(completion);
        return completion;
    }

    /** Staff see every completion; parents and players only those of their own players (naming another player is 403). */
    @Transactional
    public PageResult<PlanCompletion> list(AuthzContext caller, Optional<AssignmentId> assignmentId, Optional<PlayerId> player,
            int page, int size) {
        boolean staff = access.isStaff(caller);
        Set<PlayerId> related = access.relatedPlayers(caller);
        player.filter(p -> !staff && !related.contains(p)).ifPresent(p -> {
            throw new AccessDeniedException("Not allowed to see the completions of this player");
        });
        assignmentId.ifPresent(id -> access.requireView(caller, load(id)));
        Set<PlayerId> scope = player.map(Set::of).orElse(staff ? null : related);
        return assignments.searchCompletions(new CompletionQuery(assignmentId, scope, page, size));
    }

    /** Counts by status and the per-player state of an assignment; parents and players see their own players only. */
    @Transactional
    public PlanProgress progress(AuthzContext caller, AssignmentId assignmentId) {
        PlanAssignment assignment = load(assignmentId);
        access.requireView(caller, assignment);
        List<PlayerId> targets = targetsOf(caller, assignment);
        if (!access.isStaff(caller)) {
            Set<PlayerId> related = access.relatedPlayers(caller);
            targets = targets.stream().filter(related::contains).toList();
        }
        return PlanProgress.of(assignmentId, targets, assignments.completionsOf(assignmentId));
    }

    /** The players the assignment is for today: the team's current roster, or the one player. */
    private List<PlayerId> targetsOf(AuthzContext caller, PlanAssignment assignment) {
        List<PlayerId> roster = assignment.teamId()
                .flatMap(team -> access.teamRoster(caller.tenantId(), team)).map(TeamRoster::playerIds).orElse(List.of());
        return assignment.targets(roster);
    }

    private PlanAssignment load(AssignmentId id) {
        return assignments.find(id).orElseThrow(() -> new NotFoundException("Assignment not found"));
    }
}
