package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.domain.TrainingSchedule;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.UUID;

final class ScheduleDtos {

    static final String TIME_PATTERN = "^([01][0-9]|2[0-3]):[0-5][0-9]$";

    private ScheduleDtos() {}

    record CreateRequest(
            @NotNull UUID teamId,
            @NotNull DayOfWeek dayOfWeek,
            @NotNull @Pattern(regexp = TIME_PATTERN) String startTime,
            @NotNull @Min(15) @Max(480) Integer durationMinutes,
            @Size(max = 200) String location,
            @NotNull LocalDate validFrom,
            LocalDate validUntil) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Response(UUID id, UUID teamId, DayOfWeek dayOfWeek, String startTime, int durationMinutes, String location,
            LocalDate validFrom, LocalDate validUntil) {

        static Response from(TrainingSchedule s) {
            return new Response(s.id().value(), s.teamId().value(), s.dayOfWeek(), Requests.formatTime(s.startTime()),
                    s.durationMinutes(), s.location(), s.validFrom(), s.validUntil());
        }
    }
}
