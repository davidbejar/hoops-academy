package com.hoopsacademy.athlete.adapters.out.client;

import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.RosterPortContract;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.List;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;

/** The {@link RosterPort} contract on the REST adapter: core is a WireMock answering what core would compute. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class RestRosterPortContractTest extends RosterPortContract {

    @Inject CoreRosterAdapter adapter;

    CoreStubs stubs;

    @BeforeEach
    void resetCore() {
        stubs = new CoreStubs().reset();
        adapter.clearCache();
    }

    @Override
    protected RosterPort port() {
        return adapter;
    }

    @Override
    protected <T> T inTenant(TenantId tenant, Supplier<T> call) {
        return call.get();
    }

    @Override
    protected CoreFixture core() {
        return new CoreFixture() {
            @Override
            public void team(TenantId tenant, TeamId team, String name, List<KnownPlayer> players, List<PersonId> staff) {
                stubs.rosterOf(tenant.toString(), team.value().toString(), name, rows(players),
                        staff.stream().map(id -> id.value().toString()).toList());
            }

            @Override
            public void players(TenantId tenant, List<KnownPlayer> players) {
                stubs.playerBriefs(tenant.toString(), rows(players));
            }

            @Override
            public void unknownTeam(TenantId tenant, TeamId team) {
                stubs.rosterNotFound(tenant.toString(), team.value().toString());
            }
        };
    }

    private static List<String[]> rows(List<KnownPlayer> players) {
        return players.stream().map(p -> new String[] {p.id().value().toString(), p.displayName(),
                p.birthDate().toString(), p.gender().name(), p.status()}).toList();
    }
}
