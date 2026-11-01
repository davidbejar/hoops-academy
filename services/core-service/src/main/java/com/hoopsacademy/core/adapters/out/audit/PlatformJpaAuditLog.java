package com.hoopsacademy.core.adapters.out.audit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.PlatformAuditLog;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;

/** Tenant lifecycle actions appended by core_platform (insert-only grant and policy on core.audit_event). */
@ApplicationScoped
class PlatformJpaAuditLog implements PlatformAuditLog {

    private final EntityManager em;
    private final ObjectMapper json;
    private final TenantContext tenantContext;

    PlatformJpaAuditLog(@PersistenceUnit("platform") EntityManager em, ObjectMapper json, TenantContext tenantContext) {
        this.em = em;
        this.json = json;
        this.tenantContext = tenantContext;
    }

    @Override
    public void record(TenantId tenant, AuditEvent event) {
        AuditEventRepository.write(em, json, tenant, AuditActor.current(tenantContext), event);
    }
}
