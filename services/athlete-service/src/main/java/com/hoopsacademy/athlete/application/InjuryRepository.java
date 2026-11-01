package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Injury;
import com.hoopsacademy.athlete.domain.InjuryId;
import com.hoopsacademy.athlete.domain.InjuryStatus;
import com.hoopsacademy.athlete.domain.PlayerId;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface InjuryRepository {

    void save(Injury injury);

    Optional<Injury> find(InjuryId id);

    void delete(InjuryId id);

    /** Newest first. {@code players} null = every player of the tenant. */
    PageResult<Injury> search(Collection<PlayerId> players, Optional<InjuryStatus> status, int page, int size);

    /** The OPEN injuries of a player. */
    List<Injury> openOf(PlayerId player);

    long count();
}
