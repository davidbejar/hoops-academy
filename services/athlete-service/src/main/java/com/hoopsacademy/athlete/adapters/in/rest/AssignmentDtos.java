package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.application.ManageAssignments.AssignmentView;
import com.hoopsacademy.athlete.domain.CompletionStatus;
import com.hoopsacademy.athlete.domain.PlanAssignment;
import com.hoopsacademy.athlete.domain.PlanCompletion;
import com.hoopsacademy.athlete.domain.PlanProgress;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

final class AssignmentDtos {

    private AssignmentDtos() {}

    record CreateRequest(@NotNull UUID planId, UUID teamId, UUID playerId, @NotNull LocalDate dueOn,
            @Size(max = 2000) String notes) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Response(UUID id, PlanDtos.Summary plan, UUID teamId, UUID playerId, LocalDate dueOn, String notes,
            AttendanceDtos.PersonRef recordedBy, Instant recordedAt) {

        static Response from(AssignmentView view) {
            PlanAssignment a = view.assignment();
            return new Response(a.id().value(), PlanDtos.Summary.from(view.plan()),
                    a.teamId().map(TeamId::value).orElse(null), a.playerId().map(PlayerId::value).orElse(null), a.dueOn(),
                    a.notes(), new AttendanceDtos.PersonRef(a.assignedBy().personId().value(), a.assignedBy().displayName()),
                    a.createdAt());
        }
    }

    record CompletionRequest(@NotNull CompletionStatus status, @Size(max = 1000) String comment) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record CompletionResponse(UUID id, UUID assignmentId, UUID playerId, CompletionStatus status, String comment,
            AttendanceDtos.PersonRef recordedBy, Instant recordedAt) {

        static CompletionResponse from(PlanCompletion c) {
            return new CompletionResponse(c.id(), c.assignmentId().value(), c.playerId().value(), c.status(), c.note(),
                    new AttendanceDtos.PersonRef(c.markedBy().personId().value(), c.markedBy().displayName()), c.markedAt());
        }
    }

    /** Contract PlanProgress / PlayerProgress. */
    record Progress(UUID assignmentId, int total, int notRecorded, Map<CompletionStatus, Integer> counts,
            List<PlayerProgress> players) {

        /** {@code status}/{@code completionId} are omitted while nothing was recorded (optional in the contract). */
        @JsonInclude(JsonInclude.Include.NON_NULL)
        record PlayerProgress(UUID playerId, CompletionStatus status, UUID completionId) {}

        static Progress from(PlanProgress progress) {
            return new Progress(progress.assignmentId().value(), progress.total(), progress.notRecorded(), progress.counts(),
                    progress.players().stream().map(p -> new PlayerProgress(p.playerId().value(),
                            p.completion().map(PlanCompletion::status).orElse(null),
                            p.completion().map(PlanCompletion::id).orElse(null))).toList());
        }
    }
}
