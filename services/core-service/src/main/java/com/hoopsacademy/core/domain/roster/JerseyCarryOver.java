package com.hoopsacademy.core.domain.roster;

import java.time.LocalDate;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * The jersey of a new assignment (decision 70, ADR-0048): the requested number as given (the caller refuses a clash
 * with 409); without one, the player's preferred number when no open assignment of the team holds it, else the
 * number of the player's most recent numbered assignment when free, else none. A number held by another open
 * assignment is never taken.
 */
public final class JerseyCarryOver {

    /** Most recent first: the later joining day, then an open assignment, then the later leaving day. */
    private static final Comparator<TeamPlayer> MOST_RECENT_FIRST = Comparator
            .comparing(TeamPlayer::joinedOn)
            .thenComparing(TeamPlayer::leftOn, Comparator.nullsLast(Comparator.<LocalDate>naturalOrder()))
            .reversed();

    private JerseyCarryOver() {}

    /**
     * @param requested the number of the request, if any
     * @param preferred the player's preferred number, if any
     * @param history   the player's assignments to any team, open or closed
     * @param taken     the numbers of the team's open assignments
     */
    public static JerseyChoice choose(Optional<JerseyNumber> requested, Optional<JerseyNumber> preferred,
            List<TeamPlayer> history, Set<JerseyNumber> taken) {
        if (requested.isPresent()) {
            return new JerseyChoice(requested.get(), JerseySource.REQUESTED);
        }
        return free(preferred, taken).map(number -> new JerseyChoice(number, JerseySource.PREFERRED))
                .or(() -> free(previous(history), taken).map(number -> new JerseyChoice(number, JerseySource.PREVIOUS)))
                .orElse(JerseyChoice.NONE);
    }

    /** The number of the player's most recent assignment that had one. */
    public static Optional<JerseyNumber> previous(Collection<TeamPlayer> history) {
        return history.stream().filter(assignment -> assignment.jersey() != null).sorted(MOST_RECENT_FIRST)
                .map(TeamPlayer::jersey).findFirst();
    }

    private static Optional<JerseyNumber> free(Optional<JerseyNumber> number, Set<JerseyNumber> taken) {
        return number.filter(candidate -> !taken.contains(candidate));
    }
}
