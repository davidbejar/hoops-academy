package com.hoopsacademy.core.adapters.out.audit;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.AuditRecord;
import com.hoopsacademy.core.application.port.AuditTargetType;
import com.hoopsacademy.core.application.shared.PageRequest;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * The paged read of {@code core.audit_event e} shared by the tenant (core_app) and the platform (core_platform)
 * adapters: filter predicates, newest-first order ({@code at desc, seq desc}) and the mapping of the first nine select
 * columns ({@link #COLUMNS}) to an {@link AuditRecord}. The joins and extra columns come from an {@link AuditEventSource}.
 */
public final class AuditEventQueryRepository {

    /** The columns every caller selects first, in this order. */
    public static final String COLUMNS = "e.id, e.tenant_id, e.at, e.action, e.actor_sub, e.actor_person_id, "
            + "e.target_type, e.target_id, cast(e.metadata as text)";

    private static final TypeReference<Map<String, Object>> METADATA = new TypeReference<>() {};

    private final List<String> conditions = new ArrayList<>();
    private final Map<String, Object> parameters = new HashMap<>();

    public AuditEventQueryRepository(AuditFilter filter) {
        filter.from().ifPresent(from -> condition("e.at >= :from", "from", Timestamp.from(from)));
        filter.to().ifPresent(to -> condition("e.at < :to", "to", Timestamp.from(to)));
        if (!filter.actions().isEmpty()) {
            condition("e.action in (:actions)", "actions",
                    filter.actions().stream().map(AuditAction::wireName).sorted().toList());
        }
    }

    public AuditEventQueryRepository tenant(TenantId tenant) {
        return condition("e.tenant_id = :tenant", "tenant", tenant.value());
    }

    /** {@code select <columns> <from> where … order by … limit/offset}. */
    public List<Object[]> page(EntityManager em, AuditEventSource source, PageRequest page) {
        Query query = em.createNativeQuery("select " + source.columns() + " " + source.from() + where()
                + " order by e.at desc, e.seq desc", Object[].class);
        bind(query);
        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.setFirstResult(page.offset()).setMaxResults(page.size()).getResultList();
        return rows;
    }

    public long count(EntityManager em, AuditEventSource source) {
        Query query = em.createNativeQuery("select count(*) " + source.from() + where(), Long.class);
        bind(query);
        return ((Number) query.getSingleResult()).longValue();
    }

    /** The first nine columns of a row ({@link #COLUMNS}) as a record. */
    public static AuditRecord record(Object[] row, ObjectMapper json) {
        String action = (String) row[3];
        String targetType = (String) row[6];
        return new AuditRecord((UUID) row[0], new TenantId((UUID) row[1]), instant(row[2]),
                AuditAction.fromWireName(action)
                        .orElseThrow(() -> new IllegalStateException("Unknown audit action " + action)),
                (String) row[4], Optional.ofNullable((UUID) row[5]),
                AuditTargetType.fromWireName(targetType)
                        .orElseThrow(() -> new IllegalStateException("Unknown audit target type " + targetType)),
                (String) row[7], metadata(json, (String) row[8]));
    }

    private AuditEventQueryRepository condition(String sql, String name, Object value) {
        conditions.add(sql);
        parameters.put(name, value);
        return this;
    }

    private String where() {
        return conditions.isEmpty() ? "" : " where " + String.join(" and ", conditions);
    }

    private void bind(Query query) {
        parameters.forEach(query::setParameter);
    }

    private static Instant instant(Object value) {
        return switch (value) {
            case Instant instant -> instant;
            case OffsetDateTime offset -> offset.toInstant();
            case Timestamp timestamp -> timestamp.toInstant();
            default -> throw new IllegalStateException("Unexpected timestamp type " + value.getClass());
        };
    }

    private static Map<String, Object> metadata(ObjectMapper json, String text) {
        try {
            return json.readValue(text, METADATA);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Unreadable audit metadata", e);
        }
    }
}
