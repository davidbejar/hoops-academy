package com.hoopsacademy.common.tenancy;

import io.quarkus.arc.Arc;
import io.quarkus.arc.ManagedContext;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.function.Supplier;

/**
 * Runs work for one tenant outside an HTTP request (scheduled jobs, consumers): activates a request context if
 * needed, binds the tenant, runs the work in its OWN new transaction with {@code app.tenant_id} set, then
 * restores the previous binding (i.e. clears it for jobs). The work has no caller, so no {@link AuthzContext}.
 */
@ApplicationScoped
public class TenantScope {

    private final TenantContext tenantContext;
    private final TenantTransactions tenantTransactions;

    public TenantScope(TenantContext tenantContext, TenantTransactions tenantTransactions) {
        this.tenantContext = tenantContext;
        this.tenantTransactions = tenantTransactions;
    }

    public <T> T runAs(TenantId tenant, Supplier<T> work) {
        ManagedContext requestContext = Arc.container().requestContext();
        boolean activatedHere = !requestContext.isActive();
        if (activatedHere) {
            requestContext.activate();
        }
        try {
            return runBound(tenant, work);
        } finally {
            if (activatedHere) {
                requestContext.terminate();
            }
        }
    }

    public void runAs(TenantId tenant, Runnable work) {
        runAs(tenant, () -> {
            work.run();
            return null;
        });
    }

    private <T> T runBound(TenantId tenant, Supplier<T> work) {
        TenantContext.Snapshot previous = tenantContext.snapshot();
        tenantContext.bindTenant(tenant);
        try {
            return QuarkusTransaction.requiringNew().call(() -> {
                tenantTransactions.bindCurrentTransaction();
                return work.get();
            });
        } finally {
            tenantContext.restore(previous);
        }
    }
}
