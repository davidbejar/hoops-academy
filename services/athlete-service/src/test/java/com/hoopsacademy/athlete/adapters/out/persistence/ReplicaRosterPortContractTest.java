package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.RosterPortContract;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.ReplicaFeed;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;

/** The {@link RosterPort} contract on the replica adapter: core's events (WP67 contracts) are the fixture. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ReplicaRosterPortContractTest extends RosterPortContract {

    @Inject ReplicaRosterRepository replica;
    @Inject CoreEventDecoder decoder;
    @Inject ApplyRosterEvent apply;
    @Inject TenantScope tenantScope;

    ReplicaFeed feed;

    @BeforeEach
    void feed() {
        feed = new ReplicaFeed(decoder, apply);
    }

    @Override
    protected RosterPort port() {
        return replica;
    }

    @Override
    protected <T> T inTenant(TenantId tenant, Supplier<T> call) {
        return tenantScope.runAs(tenant, call);
    }

    @Override
    protected CoreFixture core() {
        return new CoreFixture() {
            @Override
            public void team(TenantId tenant, TeamId team, String name, List<KnownPlayer> players, List<PersonId> staff) {
                activeTenant(tenant);
                feed.apply(CoreEvents.team(tenant, team.value(), name, LocalDate.now().plusMonths(6)));
                players(tenant, players);
                players.forEach(p -> feed.apply(CoreEvents.teamPlayer(tenant, UUID.randomUUID(), team.value(),
                        p.id().value(), null, LocalDate.now().minusMonths(1), null, null)));
                staff.forEach(person -> feed.apply(CoreEvents.teamStaff(tenant, team.value(), person.value(), "COACH")));
            }

            @Override
            public void players(TenantId tenant, List<KnownPlayer> players) {
                activeTenant(tenant);
                for (KnownPlayer p : players) {
                    UUID person = UUID.randomUUID();
                    feed.apply(CoreEvents.person(tenant, person, p.displayName(), null, List.of("PLAYER"), true));
                    feed.apply(CoreEvents.player(tenant, p.id().value(), person, p.displayName(), p.status(),
                            p.birthDate(), p.gender().name()));
                }
            }

            @Override
            public void unknownTeam(TenantId tenant, TeamId team) {
                activeTenant(tenant);
            }
        };
    }

    private void activeTenant(TenantId tenant) {
        feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"));
    }
}
