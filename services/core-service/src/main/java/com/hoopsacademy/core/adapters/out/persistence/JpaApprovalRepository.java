package com.hoopsacademy.core.adapters.out.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalPayload;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import com.hoopsacademy.core.domain.approvals.ApprovalStatus;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.OptimisticLockException;
import jakarta.persistence.TypedQuery;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaApprovalRepository implements ApprovalRepository {

    private static final String TEAM = "teamId";
    private static final String JERSEY = "jerseyNumber";
    private static final String NOTE = "note";
    private static final String REASON = "reason";

    private static final TypeReference<Map<String, String>> STRINGS = new TypeReference<>() {};

    private final EntityManager em;
    private final ObjectMapper json;

    JpaApprovalRepository(EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = json;
    }

    @Override
    public void insert(ApprovalRequest request) {
        ApprovalRequestEntity row = new ApprovalRequestEntity();
        row.id = request.id().value();
        row.action = request.action().name();
        row.playerId = request.player().value();
        row.requestedByPersonId = request.requestedBy().value();
        row.createdAt = request.createdAt();
        copyMutable(request, row);
        em.persist(row);
        ConstraintConflicts.flush(em, "APPROVAL_ALREADY_PENDING",
                "A request of this kind is already pending for the player");
    }

    @Override
    public void update(ApprovalRequest request) {
        copyMutable(request, em.find(ApprovalRequestEntity.class, request.id().value()));
        try {
            em.flush();
        } catch (OptimisticLockException e) {
            throw new ConflictException("The request was decided concurrently", "CONCURRENT_DECISION");
        }
    }

    @Override
    public Optional<ApprovalRequest> find(ApprovalRequestId id) {
        return Optional.ofNullable(em.find(ApprovalRequestEntity.class, id.value())).map(this::toDomain);
    }

    @Override
    public PageResult<ApprovalRequest> list(ApprovalFilter filter, PageRequest page) {
        List<String> conditions = new ArrayList<>();
        filter.status().ifPresent(s -> conditions.add("a.status = :status"));
        filter.action().ifPresent(s -> conditions.add("a.action = :action"));
        filter.player().ifPresent(s -> conditions.add("a.playerId = :player"));
        filter.requestedBy().ifPresent(s -> conditions.add("a.requestedByPersonId = :requester"));
        String where = conditions.isEmpty() ? "" : " where " + String.join(" and ", conditions);
        TypedQuery<ApprovalRequestEntity> items = em.createQuery(
                "select a from ApprovalRequestEntity a" + where + " order by a.createdAt desc, a.id",
                ApprovalRequestEntity.class);
        TypedQuery<Long> total = em.createQuery("select count(a) from ApprovalRequestEntity a" + where, Long.class);
        for (TypedQuery<?> query : List.of(items, total)) {
            filter.status().ifPresent(s -> query.setParameter("status", s.name()));
            filter.action().ifPresent(s -> query.setParameter("action", s.name()));
            filter.player().ifPresent(s -> query.setParameter("player", s.value()));
            filter.requestedBy().ifPresent(s -> query.setParameter("requester", s.value()));
        }
        List<ApprovalRequest> found = items.setFirstResult(page.offset()).setMaxResults(page.size()).getResultStream()
                .map(this::toDomain).toList();
        return new PageResult<>(found, page, total.getSingleResult());
    }

    @Override
    public Map<PlayerId, PersonId> addRequesters(Collection<PlayerId> players) {
        if (players.isEmpty()) {
            return Map.of();
        }
        return em.createQuery("""
                        select a.playerId, a.requestedByPersonId from ApprovalRequestEntity a
                         where a.action = 'ADD_PLAYER' and a.playerId in :players""", Object[].class)
                .setParameter("players", players.stream().map(PlayerId::value).toList())
                .getResultStream()
                .collect(Collectors.toMap(row -> new PlayerId((UUID) row[0]), row -> new PersonId((UUID) row[1])));
    }

    @Override
    public long countPending() {
        return em.createQuery("select count(a) from ApprovalRequestEntity a where a.status = 'PENDING'", Long.class)
                .getSingleResult();
    }

    private void copyMutable(ApprovalRequest request, ApprovalRequestEntity row) {
        row.status = request.status().name();
        row.decidedByPersonId = request.decidedBy() == null ? null : request.decidedBy().value();
        row.decidedAt = request.decidedAt();
        row.decisionNote = request.decisionNote();
        row.payload = write(payloadOf(request.payload()));
    }

    private String write(Map<String, String> payload) {
        try {
            return json.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Approval payload is not serializable", e);
        }
    }

    private Map<String, String> read(String payload) {
        try {
            return payload == null ? Map.of() : json.readValue(payload, STRINGS);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored approval payload is not valid JSON", e);
        }
    }

    private static Map<String, String> payloadOf(ApprovalPayload payload) {
        Map<String, String> map = new HashMap<>();
        if (payload.team() != null) {
            map.put(TEAM, payload.team().value().toString());
        }
        if (payload.jersey() != null) {
            map.put(JERSEY, payload.jersey().value());
        }
        if (payload.note() != null) {
            map.put(NOTE, payload.note());
        }
        if (payload.reason() != null) {
            map.put(REASON, payload.reason());
        }
        return map;
    }

    private ApprovalRequest toDomain(ApprovalRequestEntity row) {
        Map<String, String> p = read(row.payload);
        ApprovalPayload payload = new ApprovalPayload(
                p.containsKey(TEAM) ? new TeamId(UUID.fromString(p.get(TEAM))) : null,
                JerseyNumber.ofNullable(p.get(JERSEY)), p.get(NOTE), p.get(REASON));
        return new ApprovalRequest(new ApprovalRequestId(row.id), ApprovalAction.valueOf(row.action),
                new PlayerId(row.playerId), payload, new PersonId(row.requestedByPersonId),
                ApprovalStatus.valueOf(row.status),
                row.decidedByPersonId == null ? null : new PersonId(row.decidedByPersonId), row.decidedAt,
                row.decisionNote, row.createdAt);
    }
}
