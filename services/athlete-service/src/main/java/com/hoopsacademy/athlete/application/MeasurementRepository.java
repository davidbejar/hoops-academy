package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.BodyMeasurement;
import com.hoopsacademy.athlete.domain.BodyMeasurementId;
import com.hoopsacademy.athlete.domain.PlayerId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MeasurementRepository {

    void save(BodyMeasurement measurement);

    Optional<BodyMeasurement> find(BodyMeasurementId id);

    void delete(BodyMeasurementId id);

    /** Is there a measurement of the player on that day (other than {@code except})? */
    boolean existsOn(PlayerId player, LocalDate day, Optional<BodyMeasurementId> except);

    /** Oldest first. */
    List<BodyMeasurement> history(PlayerId player, LocalDate from, LocalDate to);

    long count();
}
