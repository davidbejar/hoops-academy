package com.hoopsacademy.core.adapters.out.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.paging.PageRequest;
import com.hoopsacademy.common.paging.PageResult;
import com.hoopsacademy.common.persistence.PagedQuery;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.application.port.ApprovalRepository;
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
import java.util.Collection;
import java.util.HashMap;
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
        return PagedQuery.of(em, "from ApprovalRequestEntity a", "a")
                .whereIf(filter.status(), "a.status = :status", "status", ApprovalStatus::name)
                .whereIf(filter.action(), "a.action = :action", "action", ApprovalAction::name)
                .whereIf(filter.player(), "a.playerId = :player", "player", PlayerId::value)
                .whereIf(filter.requestedBy(), "a.requestedByPersonId = :requester", "requester", PersonId::value)
                .orderBy("a.createdAt desc, a.id")
                .page(page, "select a", ApprovalRequestEntity.class, this::toDomain);
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
