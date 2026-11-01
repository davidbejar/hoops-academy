package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;

/** Player records of the bound tenant (roster attributes arrive with WP4). */
public interface PlayerRepository {

    PlayerId create(PersonId person, PlayerStatus status);

    Optional<PlayerId> findByPerson(PersonId person);

    Map<PersonId, PlayerId> findByPersons(Collection<PersonId> persons);

    /** @return the person behind the player, if the player exists in this tenant */
    Optional<PersonId> personOf(PlayerId player);

    long count();

    long countByStatus(PlayerStatus status);
}
