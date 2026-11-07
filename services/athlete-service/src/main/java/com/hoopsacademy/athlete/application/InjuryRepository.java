package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Injury;
import com.hoopsacademy.athlete.domain.InjuryId;
import com.hoopsacademy.athlete.domain.InjuryStatus;
import com.hoopsacademy.athlete.domain.PlayerId;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface InjuryRepository {

    void save(Injury injury);

    Optional<Injury> find(InjuryId id);

    void delete(InjuryId id);

    /**
     * Newest first. {@code players} null = every player of the tenant; {@code occurredUntil} keeps the injuries that
     * occurred on or before that day (season history, ADR-0042).
     */
    PageResult<Injury> search(Collection<PlayerId> players, Optional<InjuryStatus> status, Optional<LocalDate> occurredUntil,
            int page, int size);

    /** The OPEN injuries of a player. */
    List<Injury> openOf(PlayerId player);

    long count();
}
