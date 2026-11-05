package com.hoopsacademy.core.adapters.out.audit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;

/** Appends to {@code core.audit_event} as core_app in the caller's tenant-bound transaction. */
@ApplicationScoped
class JpaAuditLog implements AuditLog {

    private final EntityManager em;
    private final ObjectMapper json;
    private final TenantContext tenantContext;

    JpaAuditLog(EntityManager em, ObjectMapper json, TenantContext tenantContext) {
        this.em = em;
        this.json = json;
        this.tenantContext = tenantContext;
    }

    @Override
    public void record(AuditEvent event) {
        AuditEventRepository.write(em, json, tenantContext.requireTenantId(), AuditActor.current(tenantContext), event);
    }

    @Override
    public void recordFor(TenantId tenant, AuditEvent event) {
        AuditEventRepository.write(em, json, tenant, AuditActor.current(tenantContext).withoutPerson(), event);
    }
}
