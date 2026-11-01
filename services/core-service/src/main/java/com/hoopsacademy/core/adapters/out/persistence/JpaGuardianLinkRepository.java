package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.GuardianLink;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaGuardianLinkRepository implements GuardianLinkRepository {

    private final EntityManager em;

    JpaGuardianLinkRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void insert(GuardianLink link) {
        GuardianLinkEntity row = new GuardianLinkEntity();
        row.id = link.id().value();
        row.guardianPersonId = link.guardian().value();
        row.playerId = link.player().value();
        row.createdAt = link.createdAt();
        em.persist(row);
    }

    @Override
    public boolean exists(PersonId guardian, PlayerId player) {
        return em.createQuery("""
                select count(g) from GuardianLinkEntity g
                 where g.guardianPersonId = :guardian and g.playerId = :player""", Long.class)
                .setParameter("guardian", guardian.value()).setParameter("player", player.value())
                .getSingleResult() > 0;
    }

    @Override
    public Optional<GuardianLink> find(GuardianLinkId id) {
        return em.createQuery("select g from GuardianLinkEntity g where g.id = :id", GuardianLinkEntity.class)
                .setParameter("id", id.value())
                .getResultStream().findFirst().map(JpaGuardianLinkRepository::toDomain);
    }

    @Override
    public void delete(GuardianLinkId id) {
        em.createQuery("delete from GuardianLinkEntity g where g.id = :id").setParameter("id", id.value())
                .executeUpdate();
    }

    @Override
    public PageResult<GuardianLink> list(Optional<PlayerId> player, Optional<PersonId> guardian, PageRequest page) {
        String where = " where (:player is null or g.playerId = :player)"
                + " and (:guardian is null or g.guardianPersonId = :guardian)";
        TypedQuery<GuardianLinkEntity> items = em.createQuery(
                "select g from GuardianLinkEntity g" + where + " order by g.createdAt, g.id", GuardianLinkEntity.class);
        TypedQuery<Long> total = em.createQuery("select count(g) from GuardianLinkEntity g" + where, Long.class);
        UUID playerId = player.map(PlayerId::value).orElse(null);
        UUID guardianId = guardian.map(PersonId::value).orElse(null);
        for (TypedQuery<?> query : java.util.List.of(items, total)) {
            query.setParameter("player", playerId).setParameter("guardian", guardianId);
        }
        return new PageResult<>(items.setFirstResult(page.offset()).setMaxResults(page.size()).getResultStream()
                .map(JpaGuardianLinkRepository::toDomain).toList(), page, total.getSingleResult());
    }

    @Override
    public Set<PlayerId> playersOf(PersonId guardian) {
        return em.createQuery("select g.playerId from GuardianLinkEntity g where g.guardianPersonId = :guardian",
                        UUID.class)
                .setParameter("guardian", guardian.value())
                .getResultStream().map(PlayerId::new).collect(Collectors.toSet());
    }

    private static GuardianLink toDomain(GuardianLinkEntity row) {
        return new GuardianLink(new GuardianLinkId(row.id), new PersonId(row.guardianPersonId),
                new PlayerId(row.playerId), row.createdAt);
    }
}
