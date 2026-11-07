package com.hoopsacademy.athlete.adapters.out.client;

import com.hoopsacademy.athlete.application.MembershipContract;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.client.RosterAuthzResolver;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;

/** The membership contract on common's REST resolver (what athlete uses with hoops.roster.source=rest). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class RestMembershipContractTest extends MembershipContract {

    @Inject CoreRosterClient coreClient;

    CoreStubs stubs;

    @BeforeEach
    void resetCore() {
        stubs = new CoreStubs().reset();
        coreClient.clearCache();
    }

    @Override
    protected AuthzContextResolver resolver() {
        return new RosterAuthzResolver(coreClient);
    }

    @Override
    protected Optional<AuthzContext> resolveInTenant(TenantId tenant, String subject) {
        return resolver().resolve(subject, tenant);
    }

    @Override
    protected CoreFixture core() {
        return new CoreFixture() {
            @Override
            public void member(TenantId tenant, Member m, String tenantStatus) {
                stubs.memberContext(tenant.toString(), m.subject(), m.personId(), tenantStatus, m.zone().getId(),
                        m.roles().stream().map(Enum::name).toList(), m.staffTeams(), m.linkedPlayers(),
                        m.ownPlayer().orElse(null), m.playerTeams(), m.historicStaffTeams());
            }

            @Override
            public void noMember(TenantId tenant, String subject) {
                stubs.notAMember(tenant.toString(), subject);
            }
        };
    }
}
