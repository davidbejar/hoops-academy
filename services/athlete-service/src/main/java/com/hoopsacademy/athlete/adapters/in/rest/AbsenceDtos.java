package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.domain.PlannedAbsence;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

final class AbsenceDtos {

    private AbsenceDtos() {}

    record CreateRequest(@NotNull UUID playerId, @NotNull LocalDate fromDate, @NotNull LocalDate toDate,
            @Size(max = 500) String reason) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Response(UUID id, UUID playerId, LocalDate fromDate, LocalDate toDate, String reason,
            AttendanceDtos.PersonRef recordedBy, Instant recordedAt) {

        static Response from(PlannedAbsence a) {
            return new Response(a.id().value(), a.playerId().value(), a.fromDate(), a.toDate(), a.reason(),
                    new AttendanceDtos.PersonRef(a.createdBy().personId().value(), a.createdBy().displayName()),
                    a.createdAt());
        }
    }
}
