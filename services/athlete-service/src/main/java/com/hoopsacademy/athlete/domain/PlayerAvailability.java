package com.hoopsacademy.athlete.domain;

import java.time.LocalDate;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/** Whether a player can train and play today, derived from the injuries; the expected return is the latest of the blocking ones. */
public record PlayerAvailability(PlayerId playerId, boolean available, Optional<LocalDate> expectedReturnOn,
        List<InjuryId> blockingInjuries) {

    public static PlayerAvailability of(PlayerId player, Collection<Injury> injuries, LocalDate today) {
        List<Injury> blocking = injuries.stream().filter(i -> i.blocksAvailability(today)).toList();
        Optional<LocalDate> expected = blocking.stream().flatMap(i -> i.expectedReturnOn().stream())
                .max(Comparator.naturalOrder());
        return new PlayerAvailability(player, blocking.isEmpty(), expected, blocking.stream().map(Injury::id).toList());
    }
}
