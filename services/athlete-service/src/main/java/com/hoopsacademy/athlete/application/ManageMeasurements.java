package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.BodyMeasurement;
import com.hoopsacademy.athlete.domain.BodyMeasurementId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/** Height and weight history: ADMIN / staff of the player's team / linked parent write, the player reads. */
@ApplicationScoped
public class ManageMeasurements {

    public record NewMeasurement(PlayerId playerId, LocalDate measuredOn, BigDecimal heightCm, BigDecimal weightKg) {}

    public record MeasurementChange(Optional<LocalDate> measuredOn, Optional<Optional<BigDecimal>> heightCm,
            Optional<Optional<BigDecimal>> weightKg) {}

    private static final LocalDate MIN_DATE = LocalDate.of(1900, 1, 1);
    private static final LocalDate MAX_DATE = LocalDate.of(9999, 12, 31);

    private final MeasurementRepository measurements;
    private final RosterPort roster;
    private final HealthAccess access;
    private final TenantClock clock;

    public ManageMeasurements(MeasurementRepository measurements, RosterPort roster, HealthAccess access, TenantClock clock) {
        this.measurements = measurements;
        this.roster = roster;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public BodyMeasurement create(AuthzContext caller, Actor actor, NewMeasurement request) {
        access.requireWriteAsFamily(caller, request.playerId());
        if (!roster.playerExists(caller.tenantId(), request.playerId())) {
            throw new NotFoundException("Player not found");
        }
        BodyMeasurement measurement = BodyMeasurement.record(request.playerId(), request.measuredOn(), request.heightCm(),
                request.weightKg(), actor, clock.now());
        requireFreeDay(measurement, Optional.empty());
        measurements.save(measurement);
        return measurement;
    }

    @Transactional
    public BodyMeasurement get(AuthzContext caller, BodyMeasurementId id) {
        BodyMeasurement measurement = measurements.find(id).orElseThrow(() -> new NotFoundException("Measurement not found"));
        access.requireRead(caller, measurement.playerId(), measurement.measuredOn(), "Measurement");
        return measurement;
    }

    @Transactional
    public BodyMeasurement update(AuthzContext caller, BodyMeasurementId id, MeasurementChange change) {
        BodyMeasurement current = get(caller, id);
        access.requireWriteAsFamily(caller, current.playerId());
        BodyMeasurement changed = current.changedTo(
                change.measuredOn().orElse(current.measuredOn()),
                Patches.apply(change.heightCm(), current.heightCm().orElse(null)),
                Patches.apply(change.weightKg(), current.weightKg().orElse(null)),
                clock.now());
        requireFreeDay(changed, Optional.of(id));
        measurements.save(changed);
        return changed;
    }

    @Transactional
    public void delete(AuthzContext caller, BodyMeasurementId id) {
        BodyMeasurement current = get(caller, id);
        access.requireWriteAsFamily(caller, current.playerId());
        measurements.delete(id);
    }

    /** Naming a player the caller may not read is 403. */
    @Transactional
    public List<BodyMeasurement> history(AuthzContext caller, PlayerId player, Optional<LocalDate> from, Optional<LocalDate> to) {
        HealthAccess.Scope scope = access.listScope(caller, Optional.of(player), Optional.empty());
        return measurements.history(player, from.orElse(MIN_DATE), scope.cap(to.orElse(MAX_DATE)));
    }

    private void requireFreeDay(BodyMeasurement measurement, Optional<BodyMeasurementId> except) {
        if (measurements.existsOn(measurement.playerId(), measurement.measuredOn(), except)) {
            throw new ConflictException("The player already has a measurement on " + measurement.measuredOn(),
                    "MEASUREMENT_EXISTS_FOR_DATE");
        }
    }
}
