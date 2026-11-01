package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** game/athlete resolve the caller through core: only members of an ACTIVE tenant resolve (others get 404). */
class RosterAuthzResolverTest {

    private final CoreRosterClientTest.FakeCore core = new CoreRosterClientTest.FakeCore();
    private final RosterAuthzResolver resolver = new RosterAuthzResolver(new CoreRosterClient(core, Duration.ofSeconds(30)));

    @Test
    void anActiveMemberResolves() {
        TenantId tenant = new TenantId(core.authz.tenantId());

        assertThat(resolver.resolve("sub-1", tenant)).hasValueSatisfying(ctx -> assertThat(ctx.subject()).isEqualTo("sub-1"));
    }

    @Test
    void suspendedAndWithdrawnTenantsDoNotResolve() {
        for (String status : new String[] {"SUSPENDED", "WITHDRAWN"}) {
            core.authz = CoreRosterClientTest.authzDto(status, null);
            TenantId tenant = new TenantId(core.authz.tenantId());

            assertThat(resolver.resolve("sub-" + status + UUID.randomUUID(), tenant)).as(status).isEmpty();
        }
    }

    @Test
    void aNonMemberDoesNotResolve() {
        core.failures.put("authz", new jakarta.ws.rs.WebApplicationException(404));

        assertThat(resolver.resolve("stranger", TenantId.random())).isEmpty();
    }
}
