package com.hoopsacademy.core.adapters.out.audit;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AuditEvent;
import jakarta.persistence.EntityManager;
import java.util.UUID;
import org.jboss.logging.Logger;

/** The insert shared by both datasources, plus one structured log line per event (category {@code hoops.audit}). */
final class AuditEventRepository {

    private static final Logger LOG = Logger.getLogger("hoops.audit");

    private AuditEventRepository() {}

    static void write(EntityManager em, ObjectMapper json, TenantId tenant, AuditActor actor, AuditEvent event) {
        em.createNativeQuery("""
                insert into core.audit_event (id, tenant_id, actor_sub, actor_person_id, action, target_type, target_id,
                                              metadata)
                values (:id, :tenant, :actor, :person, :action, :targetType, :targetId, cast(:metadata as jsonb))""")
                .setParameter("id", UUID.randomUUID())
                .setParameter("tenant", tenant.value())
                .setParameter("actor", actor.subject())
                .setParameter("person", actor.personId())
                .setParameter("action", event.action())
                .setParameter("targetType", event.targetType())
                .setParameter("targetId", event.targetId())
                .setParameter("metadata", toJson(json, event))
                .executeUpdate();
        LOG.infof("audit action=%s target=%s:%s actor=%s tenant=%s", event.action(), event.targetType(),
                event.targetId(), actor.subject(), tenant);
    }

    private static String toJson(ObjectMapper json, AuditEvent event) {
        try {
            return json.writeValueAsString(event.metadata());
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Audit metadata is not serializable: " + event.action(), e);
        }
    }
}
