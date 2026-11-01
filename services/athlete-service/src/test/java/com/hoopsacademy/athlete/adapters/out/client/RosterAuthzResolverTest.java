package com.hoopsacademy.athlete.adapters.out.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.hoopsacademy.athlete.application.MemberContext;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.TenantStatus;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The real (production) AuthzContextResolver, tested on its own because the test-jar's resolver overrides it elsewhere. */
class RosterAuthzResolverTest {

    static final TenantId TENANT = TenantId.parse("c0000000-0000-4000-8000-0000000000aa");
    final RosterPort roster = mock(RosterPort.class);
    final RosterAuthzResolver resolver = new RosterAuthzResolver(roster);

    private MemberContext member(TenantStatus status) {
        var authz = new AuthzContext("sub", UUID.randomUUID(), TENANT, Set.of(TenantRole.COACH), Set.of(), Set.of(), Optional.empty());
        return new MemberContext(authz, status, Optional.empty());
    }

    @Test
    void activeMemberResolves() {
        var member = member(TenantStatus.ACTIVE);
        when(roster.authzContext(TENANT, "sub")).thenReturn(Optional.of(member));

        assertThat(resolver.resolve("sub", TENANT)).contains(member.authz());
    }

    @Test
    void nonMemberDoesNotResolve() {
        when(roster.authzContext(TENANT, "sub")).thenReturn(Optional.empty());

        assertThat(resolver.resolve("sub", TENANT)).isEmpty();
    }

    @Test
    void suspendedOrWithdrawnTenantLooksLikeNonMembership() {
        for (TenantStatus status : new TenantStatus[] {TenantStatus.SUSPENDED, TenantStatus.WITHDRAWN}) {
            when(roster.authzContext(TENANT, "sub")).thenReturn(Optional.of(member(status)));

            assertThat(resolver.resolve("sub", TENANT)).as(status.name()).isEmpty();
        }
    }
}
