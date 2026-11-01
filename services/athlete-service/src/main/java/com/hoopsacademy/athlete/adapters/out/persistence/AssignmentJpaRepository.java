package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.AssignmentRepository;
import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.AssignmentId;
import com.hoopsacademy.athlete.domain.CompletionStatus;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlanAssignment;
import com.hoopsacademy.athlete.domain.PlanCompletion;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
class AssignmentJpaRepository implements AssignmentRepository {

    private final EntityManager em;

    AssignmentJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(PlanAssignment a) {
        AssignmentEntity entity = em.find(AssignmentEntity.class, a.id().value());
        boolean created = entity == null;
        if (created) {
            entity = new AssignmentEntity();
            entity.id = a.id().value();
            entity.planId = a.planId().value();
            entity.teamId = a.teamId().map(TeamId::value).orElse(null);
            entity.playerId = a.playerId().map(PlayerId::value).orElse(null);
        }
        entity.dueOn = a.dueOn();
        entity.notes = a.notes();
        entity.assignedByPersonId = a.assignedBy().personId().value();
        entity.assignedByName = a.assignedBy().displayName();
        entity.createdAt = a.createdAt();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<PlanAssignment> find(AssignmentId id) {
        return Optional.ofNullable(em.find(AssignmentEntity.class, id.value())).map(AssignmentJpaRepository::toDomain);
    }

    @Override
    public void delete(AssignmentId id) {
        em.flush();
        em.createQuery("delete from CompletionEntity c where c.assignmentId = :id").setParameter("id", id.value()).executeUpdate();
        em.createQuery("delete from AssignmentEntity a where a.id = :id").setParameter("id", id.value()).executeUpdate();
        em.clear();
    }

    @Override
    public boolean existsForPlan(PlanId plan) {
        return em.createQuery("select count(a) from AssignmentEntity a where a.planId = :p", Long.class)
                .setParameter("p", plan.value()).getSingleResult() > 0;
    }

    @Override
    public PageResult<PlanAssignment> search(AssignmentQuery q) {
        List<String> conditions = new ArrayList<>();
        if (q.teams() != null || q.players() != null) {
            List<String> targets = new ArrayList<>();
            if (q.teams() != null && !q.teams().isEmpty()) {
                targets.add("a.teamId in :teams");
            }
            if (q.players() != null && !q.players().isEmpty()) {
                targets.add("a.playerId in :players");
            }
            if (targets.isEmpty()) {
                return new PageResult<>(List.of(), q.page(), q.size(), 0);
            }
            conditions.add("(" + String.join(" or ", targets) + ")");
        }
        q.dueFrom().ifPresent(d -> conditions.add("a.dueOn >= :dueFrom"));
        q.dueTo().ifPresent(d -> conditions.add("a.dueOn <= :dueTo"));
        String where = conditions.isEmpty() ? "" : " where " + String.join(" and ", conditions);
        TypedQuery<AssignmentEntity> select = em.createQuery(
                "select a from AssignmentEntity a" + where + " order by a.dueOn, a.createdAt, a.id", AssignmentEntity.class);
        TypedQuery<Long> count = em.createQuery("select count(a) from AssignmentEntity a" + where, Long.class);
        for (TypedQuery<?> query : List.of(select, count)) {
            if (q.teams() != null && !q.teams().isEmpty()) {
                query.setParameter("teams", q.teams().stream().map(TeamId::value).toList());
            }
            if (q.players() != null && !q.players().isEmpty()) {
                query.setParameter("players", q.players().stream().map(PlayerId::value).toList());
            }
            q.dueFrom().ifPresent(d -> query.setParameter("dueFrom", d));
            q.dueTo().ifPresent(d -> query.setParameter("dueTo", d));
        }
        List<PlanAssignment> items = select.setFirstResult(q.page() * q.size()).setMaxResults(q.size()).getResultList()
                .stream().map(AssignmentJpaRepository::toDomain).toList();
        return new PageResult<>(items, q.page(), q.size(), count.getSingleResult());
    }

    @Override
    public List<TeamId> teamsWithAssignments() {
        return em.createQuery("select distinct a.teamId from AssignmentEntity a where a.teamId is not null", UUID.class)
                .getResultList().stream().map(TeamId::new).toList();
    }

    @Override
    public void saveCompletion(PlanCompletion c) {
        CompletionKey key = new CompletionKey(c.assignmentId().value(), c.playerId().value());
        CompletionEntity entity = em.find(CompletionEntity.class, key);
        boolean created = entity == null;
        if (created) {
            entity = new CompletionEntity();
            entity.assignmentId = key.assignmentId;
            entity.playerId = key.playerId;
            entity.id = c.id();
        }
        entity.status = c.status().name();
        entity.note = c.note();
        entity.markedAt = c.markedAt();
        entity.markedByPersonId = c.markedBy().personId().value();
        entity.markedByName = c.markedBy().displayName();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<PlanCompletion> findCompletion(AssignmentId assignment, PlayerId player) {
        return Optional.ofNullable(em.find(CompletionEntity.class, new CompletionKey(assignment.value(), player.value())))
                .map(AssignmentJpaRepository::toDomain);
    }

    @Override
    public List<PlanCompletion> completionsOf(AssignmentId assignment) {
        return em.createQuery("select c from CompletionEntity c where c.assignmentId = :a order by c.playerId",
                        CompletionEntity.class).setParameter("a", assignment.value()).getResultList().stream()
                .map(AssignmentJpaRepository::toDomain).toList();
    }

    @Override
    public PageResult<PlanCompletion> searchCompletions(CompletionQuery q) {
        if (q.players() != null && q.players().isEmpty()) {
            return new PageResult<>(List.of(), q.page(), q.size(), 0);
        }
        List<String> conditions = new ArrayList<>();
        q.assignment().ifPresent(a -> conditions.add("c.assignmentId = :assignment"));
        if (q.players() != null) {
            conditions.add("c.playerId in :players");
        }
        String where = conditions.isEmpty() ? "" : " where " + String.join(" and ", conditions);
        TypedQuery<CompletionEntity> select = em.createQuery(
                "select c from CompletionEntity c" + where + " order by c.markedAt desc, c.id", CompletionEntity.class);
        TypedQuery<Long> count = em.createQuery("select count(c) from CompletionEntity c" + where, Long.class);
        for (TypedQuery<?> query : List.of(select, count)) {
            q.assignment().ifPresent(a -> query.setParameter("assignment", a.value()));
            if (q.players() != null) {
                query.setParameter("players", q.players().stream().map(PlayerId::value).toList());
            }
        }
        List<PlanCompletion> items = select.setFirstResult(q.page() * q.size()).setMaxResults(q.size()).getResultList()
                .stream().map(AssignmentJpaRepository::toDomain).toList();
        return new PageResult<>(items, q.page(), q.size(), count.getSingleResult());
    }

    @Override
    public long countAssignments() {
        return em.createQuery("select count(a) from AssignmentEntity a", Long.class).getSingleResult();
    }

    private static PlanAssignment toDomain(AssignmentEntity e) {
        return new PlanAssignment(new AssignmentId(e.id), new PlanId(e.planId),
                e.teamId == null ? null : new TeamId(e.teamId), e.playerId == null ? null : new PlayerId(e.playerId),
                e.dueOn, e.notes, new Actor(new PersonId(e.assignedByPersonId), e.assignedByName), e.createdAt);
    }

    private static PlanCompletion toDomain(CompletionEntity e) {
        return new PlanCompletion(e.id, new AssignmentId(e.assignmentId), new PlayerId(e.playerId),
                CompletionStatus.valueOf(e.status), e.note, new Actor(new PersonId(e.markedByPersonId), e.markedByName),
                e.markedAt);
    }
}
