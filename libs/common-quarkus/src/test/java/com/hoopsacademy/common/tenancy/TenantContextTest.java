package com.hoopsacademy.common.tenancy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.jboss.logging.MDC;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class TenantContextTest {

    private final TenantContext context = new TenantContext();

    private static AuthzContext memberOf(TenantId tenant) {
        return new AuthzContext("sub", UUID.randomUUID(), tenant, Set.of(), Set.of(), Set.of(), Optional.empty());
    }

    @AfterEach
    void clearMdc() {
        MDC.remove(TenantContext.TENANT_ID_MDC_KEY);
    }

    @Test
    void bindingATenantPutsItIntoTheLoggingMdcAndClearingRemovesIt() {
        TenantId tenant = TenantId.random();

        context.bindTenant(tenant);
        assertThat(MDC.get("tenantId")).isEqualTo(tenant.toString());

        context.clear();
        assertThat(MDC.get("tenantId")).isNull();
    }

    @Test
    void restoringASnapshotRestoresTheMdcToo() {
        TenantId outer = TenantId.random();
        context.bindTenant(outer);
        TenantContext.Snapshot snapshot = context.snapshot();
        context.bindTenant(TenantId.random());

        context.restore(snapshot);
        assertThat(MDC.get("tenantId")).isEqualTo(outer.toString());

        context.restore(new TenantContext.Snapshot(null, null));
        assertThat(MDC.get("tenantId")).isNull();
    }

    @Test
    void startsUnbound() {
        assertThat(context.tenantId()).isEmpty();
        assertThatThrownBy(context::requireTenantId).isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(context::requireAuthz).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void refusesAnAuthorizationContextOfAnotherTenant() {
        context.bindTenant(TenantId.random());

        assertThatThrownBy(() -> context.bindAuthz(memberOf(TenantId.random())))
                .isInstanceOf(IllegalStateException.class);
        assertThat(context.authz()).isEmpty();
    }

    @Test
    void rebindingTheTenantDropsThePreviousAuthorization() {
        TenantId tenant = TenantId.random();
        context.bindTenant(tenant);
        context.bindAuthz(memberOf(tenant));

        context.bindTenant(TenantId.random());

        assertThat(context.authz()).isEmpty();
    }

    @Test
    void snapshotRestoresBothTenantAndAuthorization() {
        TenantId tenant = TenantId.random();
        context.bindTenant(tenant);
        context.bindAuthz(memberOf(tenant));
        TenantContext.Snapshot snapshot = context.snapshot();

        context.clear();
        context.restore(snapshot);

        assertThat(context.requireTenantId()).isEqualTo(tenant);
        assertThat(context.requireAuthz().tenantId()).isEqualTo(tenant);
    }
}
