package com.hoopsacademy.game.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.client.RosterAuthzResolver;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder;
import com.hoopsacademy.game.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.support.CoreAnswers;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreEvents.Record;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import com.hoopsacademy.game.support.ReplicaFeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

/**
 * The caller's authorisation context (ADR-0037), the same cases against both resolvers: common's REST resolver
 * (WireMock answering what core's {@code /internal/authz} answers) and the replica's (the state arrives as events).
 * Only an active person with that login in an ACTIVE tenant is a member; teams whose season has ended do not count.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class AuthzContextContractTest {

    enum Source {
        REST,
        REPLICA
    }

    private static final ZoneId ZONE = ZoneId.of("Asia/Jakarta");
    private static final LocalDate TODAY = LocalDate.now(ZONE);
    private static final LocalDate BORN = LocalDate.parse("2012-05-01");
    private static final LocalDate JOINED = LocalDate.parse("2026-09-01");

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RosterAuthzResolver rest;

    @Inject
    CoreRosterClient coreClient;

    @Inject
    ReplicaAuthzResolver replica;

    @Inject
    RosterEventDecoder decoder;

    @Inject
    ReplicateRoster replicate;

    @Inject
    TenantScope tenantScope;

    private TenantId tenant;
    private CoreEvents events;
    private UUID person;
    private String subject;
    private UUID current;
    private UUID ended;

    @BeforeEach
    void activeTenantWithACurrentAndAnEndedTeam() {
        CoreStubs.reset(core);
        coreClient.clearCache();
        tenant = TenantId.random();
        events = CoreEvents.of(tenant);
        person = UUID.randomUUID();
        subject = "sub-" + person;
        current = UUID.randomUUID();
        ended = UUID.randomUUID();
        given(Source.REPLICA, events.tenant("ACTIVE", ZONE.getId()),
                events.team(current, UUID.randomUUID(), TODAY, "Current"),
                events.team(ended, UUID.randomUUID(), TODAY.minusDays(1), "Ended"));
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aCoachIsStaffOfTheTeamsOfCurrentSeasonsOnly(Source source) {
        given(source, member(TenantRole.COACH), events.staff(current, person, "COACH"),
                events.staff(ended, person, "COACH"), events.staff(UUID.randomUUID(), person, "COACH"));
        AuthzContext expected = context(Set.of(TenantRole.COACH), Set.of(current), Set.of(), Optional.empty(), Set.of());

        assertThat(resolve(source, expected)).contains(expected);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aParentSeesTheLinkedPlayersAndTheirCurrentValidTeams(Source source) {
        UUID child = UUID.randomUUID();
        UUID closedTeam = UUID.randomUUID();
        UUID invalidTeam = UUID.randomUUID();
        given(source, member(TenantRole.PARENT), events.link(UUID.randomUUID(), person, child),
                events.player(child, UUID.randomUUID(), "Kid Ruiz", "ACTIVE", BORN, "FEMALE"),
                events.team(closedTeam, UUID.randomUUID(), TODAY.plusMonths(3), "Closed"),
                events.team(invalidTeam, UUID.randomUUID(), TODAY.plusMonths(3), "Invalid"),
                events.assignment(UUID.randomUUID(), current, child, "7", JOINED, null, null),
                events.assignment(UUID.randomUUID(), ended, child, "7", JOINED, null, null),
                events.assignment(UUID.randomUUID(), closedTeam, child, "7", JOINED, TODAY, null),
                events.assignment(UUID.randomUUID(), invalidTeam, child, "7", JOINED, null, "GENDER_POLICY"));
        AuthzContext expected = context(Set.of(TenantRole.PARENT), Set.of(), Set.of(child), Optional.empty(),
                Set.of(current));

        assertThat(resolve(source, expected)).contains(expected);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aPlayerHasTheOwnPlayerAndItsTeams(Source source) {
        UUID own = UUID.randomUUID();
        given(source, member(TenantRole.PLAYER), events.player(own, person, "Pablo Player", "ACTIVE", BORN, "MALE"),
                events.assignment(UUID.randomUUID(), current, own, "4", JOINED, null, null));
        AuthzContext expected = context(Set.of(TenantRole.PLAYER), Set.of(), Set.of(), Optional.of(own),
                Set.of(current));

        assertThat(resolve(source, expected)).contains(expected);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void playerRecordsAndLinksCountOnlyWithTheirRole(Source source) {
        UUID own = UUID.randomUUID();
        UUID child = UUID.randomUUID();
        given(source, member(TenantRole.ADMIN), events.player(own, person, "Ada Admin", "ACTIVE", BORN, "FEMALE"),
                events.link(UUID.randomUUID(), person, child),
                events.assignment(UUID.randomUUID(), current, own, "4", JOINED, null, null),
                events.assignment(UUID.randomUUID(), current, child, "5", JOINED, null, null));
        AuthzContext expected = context(Set.of(TenantRole.ADMIN), Set.of(), Set.of(), Optional.empty(), Set.of());

        assertThat(resolve(source, expected)).contains(expected);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void removedStaffEntriesAndLinksNoLongerCount(Source source) {
        UUID child = UUID.randomUUID();
        UUID link = UUID.randomUUID();
        given(source, member(TenantRole.COACH, TenantRole.PARENT), events.staff(current, person, "COACH"),
                events.link(link, person, child), events.staffRemoved(current, person),
                CoreEvents.tombstone(events.staffRemoved(current, person)), events.linkRemoved(link, person, child));
        AuthzContext expected = context(Set.of(TenantRole.COACH, TenantRole.PARENT), Set.of(), Set.of(),
                Optional.empty(), Set.of());

        assertThat(resolve(source, expected)).contains(expected);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aDeactivatedPersonIsNoMember(Source source) {
        given(source, member(TenantRole.COACH), events.person(person, "Cora Coach", subject, false, TenantRole.COACH));
        coreAnswers(source, () -> CoreAnswers.notAMember(core, tenant, subject));

        assertThat(inTenant(() -> resolver(source).resolve(subject, tenant))).isEmpty();
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aLoginMovedAwayIsNoMember(Source source) {
        given(source, member(TenantRole.COACH), events.person(person, "Cora Coach", null, true, TenantRole.COACH));
        coreAnswers(source, () -> CoreAnswers.notAMember(core, tenant, subject));

        assertThat(inTenant(() -> resolver(source).resolve(subject, tenant))).isEmpty();
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void anUnknownLoginIsNoMember(Source source) {
        given(source, member(TenantRole.COACH));
        coreAnswers(source, () -> CoreAnswers.notAMember(core, tenant, "stranger"));

        assertThat(inTenant(() -> resolver(source).resolve("stranger", tenant))).isEmpty();
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void membersOfASuspendedTenantAreNoMembers(Source source) {
        given(source, member(TenantRole.ADMIN), events.tenant("SUSPENDED", ZONE.getId()));
        coreAnswers(source, () -> CoreAnswers.member(core,
                context(Set.of(TenantRole.ADMIN), Set.of(), Set.of(), Optional.empty(), Set.of()), "SUSPENDED"));

        assertThat(inTenant(() -> resolver(source).resolve(subject, tenant))).isEmpty();
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aTenantCoreNeverReportedHasNoMembers(Source source) {
        TenantId unreported = TenantId.random();
        UUID stranger = UUID.randomUUID();
        given(source, CoreEvents.of(unreported).person(stranger, "Sam Stranger", "sub-sam", true, TenantRole.ADMIN));
        coreAnswers(source, () -> CoreAnswers.notAMember(core, unreported, "sub-sam"));

        assertThat(tenantScope.runAs(unreported, () -> resolver(source).resolve("sub-sam", unreported))).isEmpty();
    }

    private Record member(TenantRole... roles) {
        return events.person(person, "Mia Member", subject, true, roles);
    }

    private AuthzContext context(Set<TenantRole> roles, Set<UUID> staffTeams, Set<UUID> linkedPlayers,
            Optional<UUID> ownPlayer, Set<UUID> playerTeams) {
        return new AuthzContext(subject, person, tenant, roles, staffTeams, linkedPlayers, ownPlayer, playerTeams,
                Optional.of(ZONE));
    }

    private Optional<AuthzContext> resolve(Source source, AuthzContext expected) {
        coreAnswers(source, () -> CoreAnswers.member(core, expected, "ACTIVE"));
        return inTenant(() -> resolver(source).resolve(subject, tenant));
    }

    private void given(Source source, Record... records) {
        if (source == Source.REPLICA) {
            ReplicaFeed.apply(decoder, replicate, records);
        }
    }

    private void coreAnswers(Source source, Runnable stubs) {
        if (source == Source.REST) {
            stubs.run();
        }
    }

    private AuthzContextResolver resolver(Source source) {
        return source == Source.REST ? rest : replica;
    }

    private <T> T inTenant(java.util.function.Supplier<T> call) {
        return tenantScope.runAs(tenant, call);
    }
}
