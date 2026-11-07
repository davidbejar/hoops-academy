package com.hoopsacademy.core.adapters.out.platform;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.out.audit.AuditEventQueryRepository;
import com.hoopsacademy.core.adapters.out.audit.AuditEventSource;
import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.PlatformAuditTrail;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.Optional;

/**
 * Every academy's trail as core_platform (select policy {@code audit_event_platform_read}, V11), joined to the registry
 * for the academy's name. core_platform still reads no tenant content table (persons, players, …).
 */
@ApplicationScoped
class PlatformJpaAuditTrail implements PlatformAuditTrail {

    private final EntityManager em;
    private final ObjectMapper json;

    PlatformJpaAuditTrail(@PersistenceUnit("platform") EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = json;
    }

    @Override
    public PageResult<Row> list(Optional<TenantId> tenant, AuditFilter filter, PageRequest page) {
        AuditEventQueryRepository query = new AuditEventQueryRepository(filter);
        tenant.ifPresent(query::tenant);
        List<Row> items = query.page(em, AuditEventSource.PLATFORM, page).stream()
                .map(row -> new Row(AuditEventQueryRepository.record(row, json), (String) row[9])).toList();
        return new PageResult<>(items, page, query.count(em, AuditEventSource.PLATFORM));
    }
}
