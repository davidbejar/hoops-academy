package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.AbsenceId;
import com.hoopsacademy.athlete.domain.PlannedAbsence;
import com.hoopsacademy.athlete.domain.PlayerId;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface AbsenceRepository {

    void save(PlannedAbsence absence);

    Optional<PlannedAbsence> find(AbsenceId id);

    void delete(AbsenceId id);

    /** Absences overlapping [from, to] for the given players ({@code null} = every player), by start date. */
    PageResult<PlannedAbsence> search(Collection<PlayerId> players, LocalDate from, LocalDate to, int page, int size);

    /** Absences of the players that overlap the date. */
    List<PlannedAbsence> covering(Collection<PlayerId> players, LocalDate date);

    long count();
}
