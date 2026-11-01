package com.hoopsacademy.core.adapters.out.platform;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.UsageReport;
import com.hoopsacademy.core.application.port.UsageSnapshotRepository;
import com.hoopsacademy.core.application.usage.TenantUsage;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
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
                values (:id, :tenant, :collectedAt, cast(:report as jsonb))
                on conflict (tenant_id, snapshot_date) do update
                   set collected_at = excluded.collected_at, report = excluded.report
                 where jsonb_array_length(excluded.report -> 'unavailableServices') = 0
                    or jsonb_array_length(core.usage_snapshot.report -> 'unavailableServices') > 0""")
                .setParameter("id", UUID.randomUUID())
                .setParameter("tenant", tenant.value())
                .setParameter("collectedAt", collectedAt)
                .setParameter("report", toJson(report))
                .executeUpdate();
    }

    @Override
    public List<DailySnapshot> history(TenantId tenant, LocalDate from, LocalDate to) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                select snapshot_date, cast(report as text) from core.usage_snapshot
                 where tenant_id = :tenant and snapshot_date between :from and :to
                 order by snapshot_date""")
                .setParameter("tenant", tenant.value())
                .setParameter("from", from)
                .setParameter("to", to)
                .getResultList();
        return rows.stream().map(row -> new DailySnapshot(toDate(row[0]), fromJson(tenant, (String) row[1]))).toList();
    }

    private static LocalDate toDate(Object value) {
        return value instanceof java.sql.Date sql ? sql.toLocalDate() : (LocalDate) value;
    }

    /** The stored report is the contract TenantUsage JSON written by {@link #save}. */
    private TenantUsage fromJson(TenantId tenant, String report) {
        try {
            JsonNode root = json.readTree(report);
            List<UsageReport> services = new ArrayList<>();
            for (JsonNode service : root.path("services")) {
                Map<String, Long> counters = new TreeMap<>();
                service.path("counters").properties().forEach(e -> counters.put(e.getKey(), e.getValue().asLong()));
                services.add(new UsageReport(tenant, service.path("service").asText(), instant(service.get("collectedAt")),
                        instant(service.get("lastActivityAt")), counters));
            }
            List<String> unavailable = new ArrayList<>();
            root.path("unavailableServices").forEach(name -> unavailable.add(name.asText()));
            return new TenantUsage(tenant, instant(root.get("collectedAt")), services, unavailable);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored usage snapshot is not readable", e);
        }
    }

    private static Instant instant(JsonNode value) {
        return value == null || value.isNull() ? null : Instant.parse(value.asText());
    }

    private String toJson(Object report) {
        try {
            return json.writeValueAsString(report);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Usage report is not serializable", e);
        }
    }
}
