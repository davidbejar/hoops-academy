package com.hoopsacademy.game.adapters.out.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.application.MemberAccess;
import com.hoopsacademy.game.application.MemberAccess.TenantStatus;
import com.hoopsacademy.game.application.RosterPort;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class RosterAuthzResolverTest {

    private static final TenantId TENANT = TenantId.random();
    private static final UUID TEAM = UUID.randomUUID();

    private final RosterPort port = mock(RosterPort.class);
    private final RosterAuthzResolver resolver = new RosterAuthzResolver(port);

    private MemberAccess access(TenantStatus status) {
        return new MemberAccess("alice", UUID.randomUUID(), status, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(),
                Optional.empty());
    }

    @Test
    void activeTenantYieldsTheMembershipContext() {
        when(port.authzContext(TENANT, "alice")).thenReturn(Optional.of(access(TenantStatus.ACTIVE)));

        Optional<AuthzContext> ctx = resolver.resolve("alice", TENANT);

        assertThat(ctx).hasValueSatisfying(c -> {
            assertThat(c.subject()).isEqualTo("alice");
            assertThat(c.tenantId()).isEqualTo(TENANT);
            assertThat(c.isStaffOf(TEAM)).isTrue();
        });
    }

    @Test
    void suspendedAndWithdrawnTenantsHaveNoMembership() {
        when(port.authzContext(TENANT, "alice")).thenReturn(Optional.of(access(TenantStatus.SUSPENDED)));
        assertThat(resolver.resolve("alice", TENANT)).isEmpty();

        when(port.authzContext(TENANT, "alice")).thenReturn(Optional.of(access(TenantStatus.WITHDRAWN)));
        assertThat(resolver.resolve("alice", TENANT)).isEmpty();
    }

    @Test
    void nonMemberStaysEmpty() {
        when(port.authzContext(TENANT, "alice")).thenReturn(Optional.empty());

        assertThat(resolver.resolve("alice", TENANT)).isEmpty();
    }
}
