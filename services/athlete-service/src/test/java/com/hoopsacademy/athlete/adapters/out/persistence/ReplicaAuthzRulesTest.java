package com.hoopsacademy.athlete.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.ReplicaFeed;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.AuthzContext;
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
import org.junit.jupiter.api.Test;

/**
 * The replica resolver follows core's MembershipLookup: an active person with the login; the own player only for the
 * PLAYER role, linked players only for PARENT; removed links and staff entries are gone; teams whose season has ended
 * (in the tenant's zone) and closed or invalid assignments do not count.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ReplicaAuthzRulesTest {

    static final LocalDate FUTURE = LocalDate.now().plusMonths(6);
    static final LocalDate PAST = LocalDate.now().minusMonths(2);

    @Inject ReplicaAuthzResolver resolver;
    @Inject CoreEventDecoder decoder;
    @Inject ApplyRosterEvent apply;
    @Inject TenantScope tenantScope;

    ReplicaFeed feed;
    TenantId tenant;
    UUID person;
    String subject;

    @BeforeEach
    void setUp() {
        feed = new ReplicaFeed(decoder, apply);
        tenant = TenantId.random();
        person = UUID.randomUUID();
        subject = "kc-" + person;
        feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"));
    }

    @Test
    void aDeactivatedPersonIsNotAMember() {
        feed.apply(CoreEvents.person(tenant, person, "Ida Inactive", subject, List.of("COACH"), true),
                CoreEvents.person(tenant, person, "Ida Inactive", subject, List.of("COACH"), false));

        assertThat(resolve()).isEmpty();
    }

    @Test
    void aLoginMovedToAnotherPersonResolvesToTheNewPerson() {
        UUID other = UUID.randomUUID();
        feed.apply(CoreEvents.person(tenant, person, "Old Person", subject, List.of("COACH"), true),
                CoreEvents.person(tenant, person, "Old Person", null, List.of("COACH"), true),
                CoreEvents.person(tenant, other, "New Person", subject, List.of("PARENT"), true));

        assertThat(resolve().orElseThrow().personId()).isEqualTo(other);
    }

    @Test
    void aPlayerRecordCountsOnlyWithThePlayerRole() {
        UUID player = UUID.randomUUID();
        feed.apply(CoreEvents.person(tenant, person, "Cole Coach", subject, List.of("COACH"), true),
                CoreEvents.player(tenant, player, person, "Cole Coach", "WITHDRAWN", LocalDate.of(2000, 1, 1), "MALE"));

        assertThat(resolve().orElseThrow().ownPlayerId()).isEmpty();
    }

    @Test
    void guardianLinksCountOnlyWithTheParentRoleAndRemovedLinksAreGone() {
        UUID kept = UUID.randomUUID();
        UUID removed = UUID.randomUUID();
        UUID removedLink = UUID.randomUUID();
        feed.apply(CoreEvents.person(tenant, person, "Pat Parent", subject, List.of("PARENT"), true),
                CoreEvents.guardianLink(tenant, UUID.randomUUID(), person, kept),
                CoreEvents.guardianLink(tenant, removedLink, person, removed),
                CoreEvents.guardianLinkRemoved(tenant, removedLink, person, removed));

        assertThat(resolve().orElseThrow().linkedPlayerIds()).containsExactly(kept);

        feed.apply(CoreEvents.person(tenant, person, "Pat Parent", subject, List.of("COACH"), true));
        assertThat(resolve().orElseThrow().linkedPlayerIds()).isEmpty();
    }

    @Test
    void staffTeamsLeaveOutRemovedEntriesAndEndedSeasons() {
        UUID current = UUID.randomUUID();
        UUID ended = UUID.randomUUID();
        UUID detached = UUID.randomUUID();
        feed.apply(CoreEvents.person(tenant, person, "Cole Coach", subject, List.of("COACH"), true),
                CoreEvents.team(tenant, current, "Current", FUTURE), CoreEvents.team(tenant, ended, "Ended", PAST),
                CoreEvents.team(tenant, detached, "Detached", FUTURE),
                CoreEvents.teamStaff(tenant, current, person, "COACH"), CoreEvents.teamStaff(tenant, ended, person, "COACH"),
                CoreEvents.teamStaff(tenant, detached, person, "COACH"),
                CoreEvents.teamStaffRemoved(tenant, detached, person));

        assertThat(resolve().orElseThrow().staffTeamIds()).containsExactly(current);
    }

    @Test
    void aSeasonEndingTodayStillCounts() {
        UUID team = UUID.randomUUID();
        LocalDate todayInZone = LocalDate.now(java.time.ZoneId.of("Pacific/Pago_Pago"));
        feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Pacific/Pago_Pago"),
                CoreEvents.person(tenant, person, "Cole Coach", subject, List.of("COACH"), true),
                CoreEvents.team(tenant, team, "Ends today", todayInZone),
                CoreEvents.teamStaff(tenant, team, person, "COACH"));

        assertThat(resolve().orElseThrow().staffTeamIds()).containsExactly(team);
    }

    @Test
    void playerTeamsCountOnlyOpenValidAssignmentsInRunningSeasons() {
        UUID player = UUID.randomUUID();
        UUID open = UUID.randomUUID();
        UUID left = UUID.randomUUID();
        UUID invalid = UUID.randomUUID();
        UUID ended = UUID.randomUUID();
        feed.apply(CoreEvents.person(tenant, person, "Pia Player", subject, List.of("PLAYER"), true),
                CoreEvents.player(tenant, player, person, "Pia Player", "ACTIVE", LocalDate.of(2012, 1, 1), "FEMALE"),
                CoreEvents.team(tenant, open, "Open", FUTURE), CoreEvents.team(tenant, left, "Left", FUTURE),
                CoreEvents.team(tenant, invalid, "Invalid", FUTURE), CoreEvents.team(tenant, ended, "Ended", PAST),
                assignment(open, player, null, null), assignment(left, player, LocalDate.now(), null),
                assignment(invalid, player, null, "GENDER_POLICY"), assignment(ended, player, null, null));

        AuthzContext context = resolve().orElseThrow();

        assertThat(context.ownPlayerId()).contains(player);
        assertThat(context.playerTeamIds()).containsExactly(open);
    }

    @Test
    void aTeamWhoseEventHasNotArrivedDoesNotCount() {
        UUID team = UUID.randomUUID();
        feed.apply(CoreEvents.person(tenant, person, "Cole Coach", subject, List.of("COACH"), true),
                CoreEvents.teamStaff(tenant, team, person, "COACH"));

        assertThat(resolve().orElseThrow().staffTeamIds()).isEmpty();
    }

    @Test
    void aTenantTheReplicaHasNotSeenHasNoMembers() {
        TenantId unseen = TenantId.random();

        assertThat(tenantScope.runAs(unseen, () -> resolver.resolve(subject, unseen))).isEmpty();
    }

    @Test
    void aTenantThatBecomesActiveAgainHasItsMembersBack() {
        feed.apply(CoreEvents.person(tenant, person, "Ada Admin", subject, List.of("ADMIN"), true),
                CoreEvents.tenant(tenant, "SUSPENDED", "Europe/Madrid"));
        assertThat(resolve()).isEmpty();

        feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"));
        assertThat(resolve()).isPresent();
    }

    private CoreEvents.Record assignment(UUID team, UUID player, LocalDate leftOn, String invalidReason) {
        return CoreEvents.teamPlayer(tenant, UUID.randomUUID(), team, player, null, LocalDate.now().minusMonths(1), leftOn,
                invalidReason);
    }

    private Optional<AuthzContext> resolve() {
        return tenantScope.runAs(tenant, () -> resolver.resolve(subject, tenant));
    }
}
