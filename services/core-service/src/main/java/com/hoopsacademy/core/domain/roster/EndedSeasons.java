package com.hoopsacademy.core.domain.roster;

import java.time.LocalDate;
import java.util.Collection;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Which seasons are read-only history on a day (ADR-0042): those that have ended, by {@link Season#hasEnded}. */
public final class EndedSeasons {

    private EndedSeasons() {
    }

    /** The {@code ids} whose season, among {@code seasons}, has ended {@code today}; an unknown id has not. */
    public static Set<SeasonId> among(Collection<SeasonId> ids, Collection<Season> seasons, LocalDate today) {
        Map<SeasonId, Season> byId = seasons.stream().collect(Collectors.toMap(Season::id, Function.identity()));
        return ids.stream().filter(id -> byId.containsKey(id) && byId.get(id).hasEnded(today))
                .collect(Collectors.toSet());
    }
}
