package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.ScheduleId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TrainingSchedule;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ScheduleRepository {

    void save(TrainingSchedule schedule);

    /** Active schedules only; ended schedules are invisible. */
    Optional<TrainingSchedule> find(ScheduleId id);

    List<TrainingSchedule> findActive(Optional<TeamId> team, Optional<LocalDate> validOn);

    long count();
}
