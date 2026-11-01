package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.application.ManageTestResults;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.BodyMeasurement;
import com.hoopsacademy.athlete.domain.Injury;
import com.hoopsacademy.athlete.domain.InjurySeverity;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.NormBand;
import com.hoopsacademy.athlete.domain.PhysicalTestNorm;
import com.hoopsacademy.athlete.domain.PhysicalTestType;
import com.hoopsacademy.athlete.domain.PlayerAvailability;
import com.hoopsacademy.athlete.domain.InjuryId;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Request and response bodies of the health and fitness resources (libs/contracts/openapi/athlete.yaml). */
final class HealthDtos {

    private HealthDtos() {}

    private static AttendanceDtos.PersonRef ref(Actor actor) {
        return new AttendanceDtos.PersonRef(actor.personId().value(), actor.displayName());
    }

    private static Double number(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }

    // ---------------------------------------------------------------- injuries
    record CreateInjuryRequest(@NotNull UUID playerId, @NotNull LocalDate occurredOn,
            @NotBlank @Size(max = 80) String bodyPart, @NotNull InjurySeverity severity,
            @Size(max = 2000) String description, LocalDate expectedReturnOn) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record InjuryResponse(UUID id, UUID playerId, LocalDate occurredOn, String bodyPart, InjurySeverity severity,
            String description, LocalDate expectedReturnOn, LocalDate actualReturnOn, String status,
            AttendanceDtos.PersonRef recordedBy, Instant recordedAt) {

        static InjuryResponse from(Injury i) {
            return new InjuryResponse(i.id().value(), i.playerId().value(), i.occurredOn(), i.bodyPart(), i.severity(),
                    i.description(), i.expectedReturnOn().orElse(null), i.actualReturnOn().orElse(null), i.status().name(),
                    ref(i.reportedBy()), i.createdAt());
        }
    }

    /** Not in the contract yet: {@code GET /api/athlete/players/{playerId}/availability}. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record AvailabilityResponse(UUID playerId, boolean available, LocalDate expectedReturnOn, List<UUID> injuries) {

        static AvailabilityResponse from(PlayerAvailability a) {
            return new AvailabilityResponse(a.playerId().value(), a.available(), a.expectedReturnOn().orElse(null),
                    a.blockingInjuries().stream().map(InjuryId::value).toList());
        }
    }

    // ---------------------------------------------------------------- measurements
    record CreateMeasurementRequest(@NotNull UUID playerId, @NotNull LocalDate measuredOn,
            @DecimalMin("50") @DecimalMax("250") BigDecimal heightCm,
            @DecimalMin("10") @DecimalMax("250") BigDecimal weightKg) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record MeasurementResponse(UUID id, UUID playerId, LocalDate measuredOn, Double heightCm, Double weightKg,
            AttendanceDtos.PersonRef recordedBy, Instant recordedAt) {

        static MeasurementResponse from(BodyMeasurement m) {
            return new MeasurementResponse(m.id().value(), m.playerId().value(), m.measuredOn(),
                    number(m.heightCm().orElse(null)), number(m.weightKg().orElse(null)), ref(m.recordedBy()), m.createdAt());
        }
    }

    // ---------------------------------------------------------------- test types
    record CreateTestTypeRequest(@NotNull @Pattern(regexp = "[A-Z0-9_]{2,32}") String code,
            @NotBlank @Size(max = 120) String name, @NotBlank @Size(max = 16) String unit, @NotNull Boolean higherIsBetter,
            @Size(max = 2000) String description) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record TestTypeResponse(UUID id, String code, String name, String unit, boolean higherIsBetter, String description,
            boolean global) {

        static TestTypeResponse from(PhysicalTestType t) {
            return new TestTypeResponse(t.id().value(), t.code(), t.name(), t.unit(), t.higherIsBetter(), t.description(),
                    t.global());
        }
    }

    // ---------------------------------------------------------------- results
    record CreateResultRequest(@NotNull UUID playerId, @NotNull UUID testTypeId, @NotNull LocalDate measuredOn,
            @NotNull BigDecimal value, @Size(max = 1000) String notes) {}

    /**
     * Contract PhysicalTestResult: {@code bandStatus} (MATCHED, NO_NORM, MISSING_PLAYER_DATA) says why there is no band;
     * {@code ageAtMeasurement} is required and explicitly null when core has no birth date.
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record ResultResponse(UUID id, UUID playerId, UUID testTypeId, String testCode, String unit, LocalDate measuredOn,
            double value, @JsonInclude(JsonInclude.Include.ALWAYS) Integer ageAtMeasurement, NormBand expectedBand, UUID normId, boolean referencePending,
            String bandStatus, String notes, AttendanceDtos.PersonRef recordedBy, Instant recordedAt) {

        static ResultResponse from(ManageTestResults.ResultView v) {
            var r = v.result();
            return new ResultResponse(r.id().value(), r.playerId().value(), r.testTypeId().value(), v.type().code(),
                    v.type().unit(), r.measuredOn(), r.value().doubleValue(),
                    v.ageAtMeasurement().isPresent() ? v.ageAtMeasurement().getAsInt() : null,
                    v.resolution().expectedBand().orElse(null), v.resolution().norm().map(n -> n.id().value()).orElse(null),
                    v.resolution().referencePending(), v.resolution().outcome().name(), r.notes(), ref(r.recordedBy()),
                    r.createdAt());
        }
    }

    // ---------------------------------------------------------------- norms
    record NormRequest(@NotNull UUID testTypeId, @NotNull Gender gender, @NotNull @Min(3) @Max(99) Integer minAge,
            @NotNull @Min(3) @Max(99) Integer maxAge, @NotNull NormBand band, BigDecimal minValue, BigDecimal maxValue,
            @Size(max = 500) String source) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record NormResponse(UUID id, UUID testTypeId, Gender gender, int minAge, int maxAge, NormBand band, Double minValue,
            Double maxValue, String source, boolean global, boolean referencePending) {

        static NormResponse from(PhysicalTestNorm n) {
            return new NormResponse(n.id().value(), n.testTypeId().value(), n.gender(), n.minAge(), n.maxAge(), n.band(),
                    number(n.minValue().orElse(null)), number(n.maxValue().orElse(null)), n.source(), n.global(),
                    n.referencePending());
        }
    }
}
