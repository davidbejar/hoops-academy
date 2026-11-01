package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaPlayerRepository implements PlayerRepository {

    private final EntityManager em;
    private final Clock clock;

    JpaPlayerRepository(EntityManager em, Clock clock) {
        this.em = em;
        this.clock = clock;
    }

    @Override
    public PlayerId create(PersonId person, PlayerStatus status) {
        PlayerEntity row = new PlayerEntity();
        row.id = UUID.randomUUID();
        row.personId = person.value();
        row.status = status.name();
        row.createdAt = clock.instant();
        em.persist(row);
        return new PlayerId(row.id);
    }

    @Override
    public Optional<PlayerId> findByPerson(PersonId person) {
        return em.createQuery("select p.id from PlayerEntity p where p.personId = :person", UUID.class)
                .setParameter("person", person.value())
                .getResultStream().findFirst().map(PlayerId::new);
    }

    @Override
    public Map<PersonId, PlayerId> findByPersons(Collection<PersonId> persons) {
        if (persons.isEmpty()) {
            return Map.of();
        }
        return em.createQuery("select p from PlayerEntity p where p.personId in :persons", PlayerEntity.class)
                .setParameter("persons", persons.stream().map(PersonId::value).toList())
                .getResultStream()
                .collect(Collectors.toMap(p -> new PersonId(p.personId), p -> new PlayerId(p.id)));
    }

    @Override
    public Optional<PersonId> personOf(PlayerId player) {
        return em.createQuery("select p.personId from PlayerEntity p where p.id = :id", UUID.class)
                .setParameter("id", player.value())
                .getResultStream().findFirst().map(PersonId::new);
    }

    @Override
    public long count() {
        return em.createQuery("select count(p) from PlayerEntity p", Long.class).getSingleResult();
    }

    @Override
    public long countByStatus(PlayerStatus status) {
        return em.createQuery("select count(p) from PlayerEntity p where p.status = :status", Long.class)
                .setParameter("status", status.name()).getSingleResult();
    }
}
