package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.game.application.MatchFilter;
import com.hoopsacademy.game.application.MatchPage;
import com.hoopsacademy.game.application.MatchRepository;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/** JPA adapter: tenant isolation comes from Hibernate's discriminator filter plus Postgres RLS. */
@ApplicationScoped
class JpaMatchRepository implements MatchRepository {

    private final EntityManager em;

    JpaMatchRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(Match match) {
        MatchEntity entity = em.find(MatchEntity.class, match.id().value());
        boolean isNew = entity == null;
        if (isNew) {
            entity = new MatchEntity();
            entity.id = match.id().value();
            entity.teamId = match.teamId().value();
            entity.seasonId = match.seasonId().value();
            entity.createdByPersonId = match.createdByPersonId();
            entity.createdAt = Instant.now();
        }
        entity.opponentName = match.opponentName();
        entity.homeAway = match.homeAway();
        entity.scheduledAt = match.scheduledAt();
        entity.venue = match.venue();
        entity.status = match.status();
        entity.periodCount = match.periodCount();
        entity.periodMinutes = match.periodMinutes();
        entity.startedAt = match.startedAt();
        entity.finishedAt = match.finishedAt();
        entity.cancelledAt = match.cancelledAt();
        entity.cancelReason = match.cancelReason();
        entity.updatedAt = Instant.now();
        if (isNew) {
            em.persist(entity);
        }
        em.flush();
    }

    @Override
    public Optional<Match> findById(MatchId id) {
        return Optional.ofNullable(em.find(MatchEntity.class, id.value())).map(JpaMatchRepository::toDomain);
    }

    @Override
    public MatchPage list(MatchFilter filter, int page, int size) {
        StringBuilder where = new StringBuilder(" where 1 = 1");
        List<Object[]> params = new ArrayList<>();
        if (filter.teamId() != null) {
            where.append(" and m.teamId = :teamId");
            params.add(new Object[] {"teamId", filter.teamId().value()});
        }
        if (filter.seasonId() != null) {
            where.append(" and m.seasonId = :seasonId");
            params.add(new Object[] {"seasonId", filter.seasonId().value()});
        }
        if (filter.status() != null) {
            where.append(" and m.status = :status");
            params.add(new Object[] {"status", filter.status()});
        }
        if (filter.scheduledFrom() != null) {
            where.append(" and m.scheduledAt >= :from");
            params.add(new Object[] {"from", filter.scheduledFrom()});
        }
        if (filter.scheduledTo() != null) {
            where.append(" and m.scheduledAt <= :to");
            params.add(new Object[] {"to", filter.scheduledTo()});
        }
        TypedQuery<Long> count = em.createQuery("select count(m) from MatchEntity m" + where, Long.class);
        TypedQuery<MatchEntity> select =
                em.createQuery("select m from MatchEntity m" + where + " order by m.scheduledAt desc, m.id", MatchEntity.class);
        for (Object[] param : params) {
            count.setParameter((String) param[0], param[1]);
            select.setParameter((String) param[0], param[1]);
        }
        List<Match> items = select.setFirstResult(page * size).setMaxResults(size).getResultList().stream()
                .map(JpaMatchRepository::toDomain).toList();
        return new MatchPage(items, page, size, count.getSingleResult());
    }

    @Override
    public MatchRoster roster(MatchId id) {
        List<RosterEntry> entries = em.createQuery(
                        "select r from MatchRosterEntity r where r.matchId = :id order by r.displayName, r.playerId",
                        MatchRosterEntity.class)
                .setParameter("id", id.value())
                .getResultList().stream()
                .map(r -> new RosterEntry(PlayerId.of(r.playerId), r.displayName, JerseyNumber.ofNullable(r.jerseyNumber), r.starter))
                .toList();
        return new MatchRoster(id, entries);
    }

    @Override
    public void replaceRoster(MatchRoster roster) {
        em.createQuery("delete from MatchRosterEntity r where r.matchId = :id")
                .setParameter("id", roster.matchId().value())
                .executeUpdate();
        em.clear();
        for (RosterEntry entry : roster.entries()) {
            MatchRosterEntity entity = new MatchRosterEntity();
            entity.matchId = roster.matchId().value();
            entity.playerId = entry.playerId().value();
            entity.displayName = entry.displayName();
            entity.jerseyNumber = entry.jerseyNumber() == null ? null : entry.jerseyNumber().value();
            entity.starter = entry.starter();
            em.persist(entity);
        }
        em.flush();
    }

    private static Match toDomain(MatchEntity e) {
        return Match.restore(MatchId.of(e.id), TeamId.of(e.teamId), SeasonId.of(e.seasonId), e.opponentName, e.homeAway,
                e.scheduledAt, e.venue, e.status, e.periodCount, e.periodMinutes, e.startedAt, e.finishedAt,
                e.cancelledAt, e.cancelReason, e.createdByPersonId, e.version);
    }
}
