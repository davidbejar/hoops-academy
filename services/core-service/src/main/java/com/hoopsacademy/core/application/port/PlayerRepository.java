package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.eligibility.EligibilityCandidate;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/** Player records of the bound tenant; roster facts (birth date, gender, name) come from the player's person. */
public interface PlayerRepository {

    /** What the roster needs to know about a player; {@code preferredJersey} may be null (ADR-0048). */
    record PlayerSummary(PlayerId id, PersonId person, String displayName, PlayerStatus status, LocalDate birthDate,
            Gender gender, String givenName, String familyName, JerseyNumber preferredJersey) {

        public EligibilityCandidate candidate() {
            return new EligibilityCandidate(id, status, birthDate, gender);
        }
    }

    /** A player with its creation time (the list/get views). */
    record PlayerRow(PlayerSummary summary, Instant createdAt) {}

    /**
     * Which players a caller may see: {@code only} present = restricted to these ids (linked / own players);
     * {@code hidePending} = PENDING_APPROVAL players are hidden except those whose ADD request was made by
     * {@code pendingRequester}.
     */
    record Visibility(Optional<Set<PlayerId>> only, boolean hidePending, Optional<PersonId> pendingRequester) {

        public static final Visibility ALL = new Visibility(Optional.empty(), false, Optional.empty());
    }

    record PlayerFilter(Optional<PlayerStatus> status, Optional<TeamId> team, Optional<String> query,
            Visibility visibility) {}

    PlayerId create(PersonId person, PlayerStatus status);

    Optional<PlayerId> findByPerson(PersonId person);

    Map<PersonId, PlayerId> findByPersons(Collection<PersonId> persons);

    /** @return the person behind the player, if the player exists in this tenant */
    Optional<PersonId> personOf(PlayerId player);

    Optional<PlayerSummary> summary(PlayerId player);

    /** Unknown ids are omitted. */
    Map<PlayerId, PlayerSummary> summaries(Collection<PlayerId> players);

    /** Visibility is NOT applied: callers decide who may see the row. */
    Optional<PlayerRow> find(PlayerId player);

    PageResult<PlayerRow> page(PlayerFilter filter, PageRequest page);

    void updateStatus(PlayerId player, PlayerStatus status);

    /** Stores the preferred number ({@code null} clears it); no roster event, which does not carry it. */
    void updatePreferredJersey(PlayerId player, JerseyNumber preferred);

    long count();

    long countByStatus(PlayerStatus status);

    /** Players per status (statuses without players are omitted). */
    Map<PlayerStatus, Long> countsByStatus();
}
