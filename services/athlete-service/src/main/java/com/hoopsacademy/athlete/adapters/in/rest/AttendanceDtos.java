package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.domain.Attendance;
import com.hoopsacademy.athlete.domain.AttendanceEntry;
import com.hoopsacademy.athlete.domain.AttendanceStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class AttendanceDtos {

    private AttendanceDtos() {}

    record Input(@NotNull UUID playerId, @NotNull AttendanceStatus status, @Min(1) @Max(480) Integer minutesLate,
            @Size(max = 500) String note) {}

    record RecordRequest(@NotEmpty @Size(max = 100) List<@Valid @NotNull Input> entries) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record PersonRef(UUID personId, String displayName) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Entry(UUID playerId, AttendanceStatus status, Integer minutesLate, String note, boolean expectedAbsent,
            UUID plannedAbsenceId, PersonRef recordedBy, Instant recordedAt) {

        static Entry from(AttendanceEntry entry) {
            Attendance a = entry.recorded().orElse(null);
            return new Entry(entry.playerId().value(), a == null ? null : a.status(), a == null ? null : a.minutesLate(),
                    a == null ? null : a.note(), entry.expectedAbsent(),
                    entry.plannedAbsence().map(p -> p.id().value()).orElse(null),
                    a == null ? null : new PersonRef(a.recordedBy().personId().value(), a.recordedBy().displayName()),
                    a == null ? null : a.recordedAt());
        }
    }

    record Sheet(UUID sessionId, List<Entry> entries) {}
}
