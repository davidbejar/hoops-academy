package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.AssignmentId;
import com.hoopsacademy.athlete.domain.PlanAssignment;
import com.hoopsacademy.athlete.domain.PlanCompletion;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** Plan assignments and the completions recorded for them (tenant scoped by RLS). */
public interface AssignmentRepository {

    /**
     * Assignments addressed to one of the teams OR to one of the players; a {@code null} collection means "not
     * restricted" and both {@code null} means every assignment. An empty collection matches nothing.
     */
    record AssignmentQuery(Collection<TeamId> teams, Collection<PlayerId> players, Optional<LocalDate> dueFrom,
            Optional<LocalDate> dueTo, int page, int size) {}

    /** Completions of one assignment and/or of the given players ({@code null} = any player). */
    record CompletionQuery(Optional<AssignmentId> assignment, Collection<PlayerId> players, int page, int size) {}

    void save(PlanAssignment assignment);

    Optional<PlanAssignment> find(AssignmentId id);

    /** Deletes the assignment together with its completions. */
    void delete(AssignmentId id);

    boolean existsForPlan(PlanId plan);

    PageResult<PlanAssignment> search(AssignmentQuery query);

    /** Teams that currently have at least one team assignment (candidates for the per-player fan-out). */
    List<TeamId> teamsWithAssignments();

    void saveCompletion(PlanCompletion completion);

    Optional<PlanCompletion> findCompletion(AssignmentId assignment, PlayerId player);

    List<PlanCompletion> completionsOf(AssignmentId assignment);

    PageResult<PlanCompletion> searchCompletions(CompletionQuery query);

    long countAssignments();
}
