package com.hoopsacademy.core.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import java.util.UUID;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * The LOGIN_SHARED probe (ADR-0023) reads other tenants' index rows of ONE login through the subject policy, as
 * core_app inside a tenant transaction — and must leave that transaction exactly as tenant-bound as before.
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class SharedLoginProbeTest {

    @Inject
    MembershipRepository memberships;

    @Inject
    TenantScope tenantScope;

    @Inject
    EntityManager em;

    @Test
    void onlyAnActiveLinkInAnotherTenantCounts() {
        String home = Members.newTenant();
        String sub = "probe-" + UUID.randomUUID();
        UUID login = CoreDb.login(sub);
        CoreDb.person(home, login, "Pro", "Be", null, null, null, TenantRole.COACH);
        assertThat(probe(home, sub)).as("linked here only").isFalse();
        assertThat(probe(home, "unknown-" + UUID.randomUUID())).isFalse();

        CoreDb.person(Members.newTenant(), login, "Pro", "Be", null, null, null, TenantRole.PARENT);
        assertThat(probe(home, sub)).isTrue();
    }

    @Test
    void theProbeRestoresTheSubjectSoOtherTenantsStayInvisible() {
        String home = Members.newTenant();
        String sub = "probe-" + UUID.randomUUID();
        UUID login = CoreDb.login(sub);
        CoreDb.person(home, login, "Pro", "Be", null, null, null, TenantRole.COACH);
        CoreDb.person(Members.newTenant(), login, "Pro", "Be", null, null, null, TenantRole.PARENT);

        Object[] after = tenantScope.runAs(TenantId.parse(home), () -> {
            memberships.linkedInAnotherTenant(sub);
            return (Object[]) em.createNativeQuery("""
                    select coalesce(current_setting('app.subject', true), ''),
                           (select count(*) from core.user_membership_index where keycloak_sub = :sub)""")
                    .setParameter("sub", sub).getSingleResult();
        });
        assertThat(after[0]).isEqualTo("");
        assertThat(((Number) after[1]).longValue()).as("own tenant's row only").isEqualTo(1);
    }

    private boolean probe(String tenant, String subject) {
        return tenantScope.runAs(TenantId.parse(tenant), () -> memberships.linkedInAnotherTenant(subject));
    }
}
