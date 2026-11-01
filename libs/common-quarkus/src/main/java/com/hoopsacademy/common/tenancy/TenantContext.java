package com.hoopsacademy.common.tenancy;

import jakarta.enterprise.context.RequestScoped;
import java.util.Objects;
import java.util.Optional;
import org.jboss.logging.MDC;

/**
 * The tenant (and caller authorization) bound to the current request or {@link TenantScope} job.
 * Bound by {@link TenantHeaderFilter} for {@code /api/**}; read by the transaction interceptor, the Hibernate
 * tenant resolver, {@code @RequiresTenantRole} and outbound client filters. The bound tenant is mirrored into the
 * logging MDC ({@value #TENANT_ID_MDC_KEY}) so JSON log lines carry it next to {@code traceId}.
 */
@RequestScoped
public class TenantContext {

    /** Logging MDC key carrying the bound tenant (JSON logs, ADR-0017). */
    public static final String TENANT_ID_MDC_KEY = "tenantId";

    private TenantId tenantId;
    private AuthzContext authz;

    public Optional<TenantId> tenantId() {
        return Optional.ofNullable(tenantId);
    }

    public Optional<AuthzContext> authz() {
        return Optional.ofNullable(authz);
    }

    public TenantId requireTenantId() {
        return tenantId().orElseThrow(() -> new IllegalStateException("No tenant bound to the current context"));
    }

    public AuthzContext requireAuthz() {
        return authz().orElseThrow(() -> new IllegalStateException("No authorization context bound"));
    }

    void bindTenant(TenantId tenant) {
        this.tenantId = Objects.requireNonNull(tenant, "tenant");
        this.authz = null;
        syncMdc();
    }

    void bindAuthz(AuthzContext context) {
        if (!context.tenantId().equals(tenantId)) {
            throw new IllegalStateException("Authorization context belongs to another tenant than the bound one");
        }
        this.authz = context;
    }

    void clear() {
        tenantId = null;
        authz = null;
        syncMdc();
    }

    /** Captures the current binding so a nested scope can put it back. */
    Snapshot snapshot() {
        return new Snapshot(tenantId, authz);
    }

    void restore(Snapshot snapshot) {
        tenantId = snapshot.tenantId();
        authz = snapshot.authz();
        syncMdc();
    }

    private void syncMdc() {
        if (tenantId == null) {
            MDC.remove(TENANT_ID_MDC_KEY);
        } else {
            MDC.put(TENANT_ID_MDC_KEY, tenantId.toString());
        }
    }

    record Snapshot(TenantId tenantId, AuthzContext authz) {}
}
