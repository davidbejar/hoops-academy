package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.domain.SessionStatus;
import com.hoopsacademy.athlete.domain.TrainingSession;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

final class SessionDtos {

    private SessionDtos() {}

    record CreateRequest(
            @NotNull UUID teamId,
            @NotNull Instant startsAt,
            @NotNull @Min(15) @Max(480) Integer durationMinutes,
            @Size(max = 200) String location,
            UUID planId,
            @Size(max = 2000) String notes) {}

    record CancelRequest(@NotBlank @Size(max = 500) String reason) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Response(UUID id, UUID teamId, UUID scheduleId, Instant startsAt, int durationMinutes, String location,
            SessionStatus status, UUID planId, String notes, String cancelReason) {

        static Response from(TrainingSession s) {
            return new Response(s.id().value(), s.teamId().value(),
                    s.schedule().map(id -> id.value()).orElse(null), s.startsAt(), s.durationMinutes(), s.location(),
                    s.status(), s.planId(), s.notes(), s.cancelReason());
        }
    }
}
