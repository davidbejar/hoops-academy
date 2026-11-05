package com.hoopsacademy.core.adapters.out.audit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.AuditRecord;
import com.hoopsacademy.core.application.port.AuditTrail;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;

/**
 * The bound tenant's trail as core_app: RLS admits only that tenant's rows; the explicit {@code tenant_id} predicate
 * repeats it so the {@code (tenant_id, …, at desc)} indexes apply.
 */
@ApplicationScoped
class JpaAuditTrail implements AuditTrail {

    private static final String FROM = "from core.audit_event e";

    private final EntityManager em;
    private final ObjectMapper json;
    private final TenantContext tenantContext;

    JpaAuditTrail(EntityManager em, ObjectMapper json, TenantContext tenantContext) {
        this.em = em;
        this.json = json;
        this.tenantContext = tenantContext;
    }

    @Override
    public PageResult<AuditRecord> list(AuditFilter filter, PageRequest page) {
        AuditEventQueryRepository query = new AuditEventQueryRepository(filter).tenant(tenantContext.requireTenantId());
        List<AuditRecord> items = query.page(em, AuditEventQueryRepository.COLUMNS, FROM, page).stream()
                .map(row -> AuditEventQueryRepository.record(row, json)).toList();
        return new PageResult<>(items, page, query.count(em, FROM));
    }
}
