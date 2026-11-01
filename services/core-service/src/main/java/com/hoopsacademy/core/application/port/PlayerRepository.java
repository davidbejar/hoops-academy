package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.eligibility.EligibilityCandidate;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;

/** Player records of the bound tenant; roster facts (birth date, gender, name) come from the player's person. */
public interface PlayerRepository {

    /** What the roster needs to know about a player. */
    record PlayerSummary(PlayerId id, PersonId person, String displayName, PlayerStatus status, LocalDate birthDate,
            Gender gender) {

        public EligibilityCandidate candidate() {
            return new EligibilityCandidate(id, status, birthDate, gender);
        }
    }

    PlayerId create(PersonId person, PlayerStatus status);

    Optional<PlayerId> findByPerson(PersonId person);

    Map<PersonId, PlayerId> findByPersons(Collection<PersonId> persons);

    /** @return the person behind the player, if the player exists in this tenant */
    Optional<PersonId> personOf(PlayerId player);

    Optional<PlayerSummary> summary(PlayerId player);

    /** Unknown ids are omitted. */
    Map<PlayerId, PlayerSummary> summaries(Collection<PlayerId> players);

    void updateStatus(PlayerId player, PlayerStatus status);

    long count();

    long countByStatus(PlayerStatus status);
}
