package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.application.MembershipContract;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.ReplicaFeed;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;

/** The membership contract on the replica resolver: core's events are the fixture. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ReplicaMembershipContractTest extends MembershipContract {

    @Inject ReplicaAuthzResolver replicaResolver;
    @Inject CoreEventDecoder decoder;
    @Inject ApplyRosterEvent apply;
    @Inject TenantScope tenantScope;

    ReplicaFeed feed;

    @BeforeEach
    void feed() {
        feed = new ReplicaFeed(decoder, apply);
    }

    @Override
    protected AuthzContextResolver resolver() {
        return replicaResolver;
    }

    @Override
    protected Optional<AuthzContext> resolveInTenant(TenantId tenant, String subject) {
        return tenantScope.runAs(tenant, () -> replicaResolver.resolve(subject, tenant));
    }

    @Override
    protected CoreFixture core() {
        return new CoreFixture() {
            @Override
            public void member(TenantId tenant, Member m, String tenantStatus) {
                LocalDate seasonEnd = LocalDate.now().plusMonths(6);
                feed.apply(CoreEvents.tenant(tenant, tenantStatus, m.zone().getId()));
                feed.apply(CoreEvents.person(tenant, m.personId(), "Mia Member", m.subject(),
                        m.roles().stream().map(Enum::name).toList(), true));
                m.ownPlayer().ifPresent(player -> feed.apply(CoreEvents.player(tenant, player, m.personId(), "Mia Member",
                        "ACTIVE", LocalDate.of(2012, 1, 1), "FEMALE")));
                m.linkedPlayers().forEach(player -> feed.apply(
                        CoreEvents.guardianLink(tenant, UUID.randomUUID(), m.personId(), player)));
                m.staffTeams().forEach(team -> feed.apply(CoreEvents.team(tenant, team, "Staff team", seasonEnd),
                        CoreEvents.teamStaff(tenant, team, m.personId(), "COACH")));
                UUID playerOfTeams = m.ownPlayer().orElseGet(() -> m.linkedPlayers().isEmpty() ? null : m.linkedPlayers().get(0));
                m.playerTeams().forEach(team -> feed.apply(CoreEvents.team(tenant, team, "Player team", seasonEnd),
                        CoreEvents.teamPlayer(tenant, UUID.randomUUID(), team, playerOfTeams, null,
                                LocalDate.now().minusMonths(1), null, null)));
            }

            @Override
            public void noMember(TenantId tenant, String subject) {
                feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"));
                feed.apply(CoreEvents.person(tenant, UUID.randomUUID(), "Someone Else", "kc-someone-else",
                        List.of("ADMIN"), true));
            }
        };
    }
}
