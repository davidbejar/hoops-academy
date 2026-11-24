package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.paging.PageRequest;
import com.hoopsacademy.common.paging.PageResult;
import com.hoopsacademy.common.persistence.PagedQuery;
import com.hoopsacademy.core.application.events.RosterChanges;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaPlayerRepository implements PlayerRepository {

    private static final UUID NO_ONE = new UUID(0, 0);

    private final EntityManager em;
    private final RosterChanges changes;
    private final Clock clock;

    JpaPlayerRepository(EntityManager em, Clock clock, RosterChanges changes) {
        this.em = em;
        this.changes = changes;
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
        PlayerId id = new PlayerId(row.id);
        changes.player(id);
        return id;
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
    public Optional<PlayerSummary> summary(PlayerId player) {
        return Optional.ofNullable(summaries(List.of(player)).get(player));
    }

    @Override
    public Map<PlayerId, PlayerSummary> summaries(Collection<PlayerId> players) {
        if (players.isEmpty()) {
            return Map.of();
        }
        return em.createQuery("""
                        select p, pe from PlayerEntity p, PersonEntity pe
                         where pe.id = p.personId and p.id in :ids""", Object[].class)
                .setParameter("ids", players.stream().map(PlayerId::value).distinct().toList())
                .getResultStream()
                .map(row -> toSummary((PlayerEntity) row[0], (PersonEntity) row[1]))
                .collect(Collectors.toMap(PlayerSummary::id, summary -> summary));
    }

    @Override
    public Optional<PlayerRow> find(PlayerId player) {
        return em.createQuery("""
                        select p, pe from PlayerEntity p, PersonEntity pe
                         where pe.id = p.personId and p.id = :id""", Object[].class)
                .setParameter("id", player.value()).getResultStream().findFirst()
                .map(row -> toRow((PlayerEntity) row[0], (PersonEntity) row[1]));
    }

    @Override
    public PageResult<PlayerRow> page(PlayerFilter filter, PageRequest page) {
        Visibility visibility = filter.visibility();
        if (visibility.only().filter(Set::isEmpty).isPresent()) {
            return new PageResult<>(List.of(), page, 0);
        }
        PagedQuery query = PagedQuery.of(em, "from PlayerEntity p, PersonEntity pe", "p")
                .where("pe.id = p.personId")
                .whereIf(filter.status(), "p.status = :status", "status", PlayerStatus::name)
                .whereIf(filter.team(), """
                        exists (select 1 from TeamPlayerEntity a
                                 where a.playerId = p.id and a.teamId = :team and a.leftOn is null)""",
                        "team", TeamId::value)
                .whereIf(filter.query(), "lower(concat(pe.givenName, ' ', pe.familyName)) like :query escape '\\'",
                        "query", LikePattern::contains)
                .whereIf(visibility.only(), "p.id in :only", "only",
                        ids -> ids.stream().map(PlayerId::value).toList());
        if (visibility.hidePending()) {
            query.where("""
                    (p.status not in ('PENDING_APPROVAL', 'REJECTED') or exists (select 1 from ApprovalRequestEntity r
                       where r.playerId = p.id and r.action = 'ADD_PLAYER' and r.requestedByPersonId = :requester))""",
                    "requester", visibility.pendingRequester().map(PersonId::value).orElse(NO_ONE));
        }
        return query.orderBy("pe.familyName, pe.givenName, p.id")
                .page(page, "select p, pe", Object[].class, row -> toRow((PlayerEntity) row[0], (PersonEntity) row[1]));
    }

    private static PlayerRow toRow(PlayerEntity player, PersonEntity person) {
        return new PlayerRow(toSummary(player, person), player.createdAt);
    }

    @Override
    public void updateStatus(PlayerId player, PlayerStatus status) {
        em.createQuery("select p from PlayerEntity p where p.id = :id", PlayerEntity.class)
                .setParameter("id", player.value()).getResultStream().findFirst()
                .ifPresent(row -> {
                    row.status = status.name();
                    changes.player(player);
                });
    }

    @Override
    public void updatePreferredJersey(PlayerId player, JerseyNumber preferred) {
        em.createQuery("select p from PlayerEntity p where p.id = :id", PlayerEntity.class)
                .setParameter("id", player.value()).getResultStream().findFirst()
                .ifPresent(row -> row.preferredJerseyNumber = preferred == null ? null : preferred.value());
    }

    @Override
    public Map<PlayerStatus, Long> countsByStatus() {
        Map<PlayerStatus, Long> counts = new java.util.EnumMap<>(PlayerStatus.class);
        em.createQuery("select p.status, count(p) from PlayerEntity p group by p.status", Object[].class)
                .getResultList().forEach(row -> counts.put(PlayerStatus.valueOf((String) row[0]), (Long) row[1]));
        return counts;
    }

    private static PlayerSummary toSummary(PlayerEntity player, PersonEntity person) {
        return new PlayerSummary(new PlayerId(player.id), new PersonId(person.id),
                person.givenName + " " + person.familyName, PlayerStatus.valueOf(player.status), person.birthDate,
                person.gender == null ? null : Gender.valueOf(person.gender), person.givenName, person.familyName,
                JerseyNumber.ofNullable(player.preferredJerseyNumber));
    }
}
