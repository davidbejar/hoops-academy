package com.hoopsacademy.core.adapters.out.platform;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.UsageSnapshotRepository;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.UUID;

@ApplicationScoped
class PlatformUsageSnapshotRepository implements UsageSnapshotRepository {

    private final EntityManager em;
    private final ObjectMapper json;

    PlatformUsageSnapshotRepository(@PersistenceUnit("platform") EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = json;
    }

    @Override
    public void save(TenantId tenant, Instant collectedAt, Object report) {
        em.createNativeQuery("""
                insert into core.usage_snapshot (id, tenant_id, collected_at, report)
                values (:id, :tenant, :collectedAt, cast(:report as jsonb))""")
                .setParameter("id", UUID.randomUUID())
                .setParameter("tenant", tenant.value())
                .setParameter("collectedAt", collectedAt)
                .setParameter("report", toJson(report))
                .executeUpdate();
    }

    private String toJson(Object report) {
        try {
            return json.writeValueAsString(report);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Usage report is not serializable", e);
        }
    }
}
