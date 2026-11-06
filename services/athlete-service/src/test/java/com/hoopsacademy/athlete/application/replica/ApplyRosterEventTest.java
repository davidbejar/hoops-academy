package com.hoopsacademy.athlete.application.replica;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.adapters.out.persistence.ReplicaRosterRepository;
import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent.Outcome;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.ReplicaFeed;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.assertj.core.api.ThrowableAssert.ThrowingCallable;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Applying core's events to the replica tables: upsert by aggregate, an older occurredAt never overwrites a newer one,
 * a redelivered eventId is ignored, removals stay removed against late older changes, and every row lands in the
 * event's own tenant (RLS bound per event).
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ApplyRosterEventTest {

    static final LocalDate SEASON_END = LocalDate.now().plusMonths(6);

    @Inject CoreEventDecoder decoder;
    @Inject ApplyRosterEvent apply;
    @Inject ReplicaRosterRepository replica;
    @Inject TenantScope tenantScope;
    @Inject TenantRegistry registry;

    ReplicaFeed feed;
    TenantId tenant;
    UUID team;

    @BeforeEach
    void setUp() {
        feed = new ReplicaFeed(decoder, apply);
        tenant = TenantId.random();
        team = UUID.randomUUID();
        feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"));
    }

    @Test
    void aNewerEventReplacesTheAggregatesState() {
        assertThat(feed.apply(CoreEvents.team(tenant, team, "U12", SEASON_END),
                CoreEvents.team(tenant, team, "U12 Lions", SEASON_END))).containsExactly(Outcome.APPLIED, Outcome.APPLIED);

        assertThat(roster().teamName()).isEqualTo("U12 Lions");
    }

    @Test
    void aRedeliveredEventIsADuplicateAndChangesNothing() {
        CoreEvents.Record first = CoreEvents.team(tenant, team, "U12", SEASON_END);
        CoreEvents.Record second = CoreEvents.team(tenant, team, "U14", SEASON_END);

        assertThat(feed.apply(first, second, first)).containsExactly(Outcome.APPLIED, Outcome.APPLIED, Outcome.DUPLICATE);

        assertThat(roster().teamName()).isEqualTo("U14");
        assertThat(count("select count(*) from athlete.applied_event where tenant_id = ?")).isEqualTo(3);
    }

    @Test
    void anOlderEventArrivingLateIsStaleAndNeverOverwritesTheNewerState() {
        CoreEvents.Record newer = CoreEvents.team(tenant, team, "Newer", SEASON_END);
        CoreEvents.Record older = CoreEvents.team(tenant, team, "Older", SEASON_END).at(newer.occurredAt().minusSeconds(5));

        assertThat(feed.apply(newer, older)).containsExactly(Outcome.APPLIED, Outcome.STALE);

        assertThat(roster().teamName()).isEqualTo("Newer");
    }

    @Test
    void aStaleEventIsStillRecordedSoItsRedeliveryIsADuplicate() {
        CoreEvents.Record newer = CoreEvents.team(tenant, team, "Newer", SEASON_END);
        CoreEvents.Record older = CoreEvents.team(tenant, team, "Older", SEASON_END).at(newer.occurredAt().minusSeconds(5));

        assertThat(feed.apply(newer, older, older)).containsExactly(Outcome.APPLIED, Outcome.STALE, Outcome.DUPLICATE);
    }

    @Test
    void anEventWithTheSameInstantAsTheStoredOneIsAppliedInDeliveryOrder() {
        CoreEvents.Record first = CoreEvents.team(tenant, team, "First", SEASON_END);
        CoreEvents.Record sameInstant = CoreEvents.team(tenant, team, "Same instant", SEASON_END).at(first.occurredAt());

        assertThat(feed.apply(first, sameInstant)).containsExactly(Outcome.APPLIED, Outcome.APPLIED);

        assertThat(roster().teamName()).isEqualTo("Same instant");
    }

    @Test
    void aRemovedStaffEntryStaysRemovedWhenAnOlderChangeArrivesLate() {
        UUID coach = UUID.randomUUID();
        feed.apply(CoreEvents.team(tenant, team, "U12", SEASON_END));
        CoreEvents.Record added = CoreEvents.teamStaff(tenant, team, coach, "COACH");
        CoreEvents.Record removed = CoreEvents.teamStaffRemoved(tenant, team, coach);

        assertThat(feed.apply(added, removed, added.at(removed.occurredAt().minusSeconds(1))))
                .containsExactly(Outcome.APPLIED, Outcome.APPLIED, Outcome.STALE);

        assertThat(roster().staff()).isEmpty();
    }

    @Test
    void aStaffEntryAddedAgainAfterItsRemovalIsBack() {
        UUID coach = UUID.randomUUID();
        feed.apply(CoreEvents.team(tenant, team, "U12", SEASON_END), CoreEvents.teamStaff(tenant, team, coach, "COACH"),
                CoreEvents.teamStaffRemoved(tenant, team, coach), CoreEvents.teamStaff(tenant, team, coach, "ASSISTANT_COACH"));

        assertThat(roster().staff()).extracting(staff -> staff.value()).containsExactly(coach);
    }

    @Test
    void aRemovalOfAnEntryNeverSeenIsKeptAsRemoved() {
        UUID coach = UUID.randomUUID();
        feed.apply(CoreEvents.team(tenant, team, "U12", SEASON_END));
        CoreEvents.Record removed = CoreEvents.teamStaffRemoved(tenant, team, coach);
        CoreEvents.Record olderAdd = CoreEvents.teamStaff(tenant, team, coach, "COACH").at(removed.occurredAt().minusSeconds(1));

        assertThat(feed.apply(removed, olderAdd)).containsExactly(Outcome.APPLIED, Outcome.STALE);

        assertThat(roster().staff()).isEmpty();
    }

    @Test
    void everyAggregateOfTheRosterIsUpserted() {
        UUID person = UUID.randomUUID();
        UUID player = UUID.randomUUID();
        UUID assignment = UUID.randomUUID();
        UUID link = UUID.randomUUID();
        List<Outcome> outcomes = feed.apply(
                CoreEvents.person(tenant, person, "Pablo Player", "kc-" + person, List.of("PLAYER"), true),
                CoreEvents.player(tenant, player, person, "Pablo Player", "ACTIVE", LocalDate.of(2014, 3, 9), "MALE"),
                CoreEvents.team(tenant, team, "U12", SEASON_END),
                CoreEvents.teamPlayer(tenant, assignment, team, player, "7", LocalDate.of(2026, 9, 15), null, null),
                CoreEvents.teamStaff(tenant, team, UUID.randomUUID(), "COACH"),
                CoreEvents.guardianLink(tenant, link, UUID.randomUUID(), player),
                CoreEvents.guardianLinkRemoved(tenant, link, UUID.randomUUID(), player));

        assertThat(outcomes).containsOnly(Outcome.APPLIED);
        assertThat(roster().playerIds()).containsExactly(new PlayerId(player));
        assertThat(count("select count(*) from athlete.guardian_link_ref where tenant_id = ? and removed")).isEqualTo(1);
    }

    @Test
    void theTenantsZoneReachesTheTenantRegistry() {
        feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Asia/Jakarta"));

        assertThat(registry.zoneOf(tenant)).contains(ZoneId.of("Asia/Jakarta"));
    }

    @Test
    void anEventOfAnotherTenantIsInvisibleInThisTenant() {
        TenantId other = TenantId.random();
        feed.apply(CoreEvents.tenant(other, "ACTIVE", "Europe/Madrid"), CoreEvents.team(other, team, "Theirs", SEASON_END));

        assertThat(tenantScope.runAs(other, () -> replica.teamRoster(other, new TeamId(team))).teamName())
                .isEqualTo("Theirs");
        assertNotFound(() -> tenantScope.runAs(tenant, () -> replica.teamRoster(tenant, new TeamId(team))));
    }

    private com.hoopsacademy.athlete.application.TeamRoster roster() {
        return tenantScope.runAs(tenant, () -> replica.teamRoster(tenant, new TeamId(team)));
    }

    private static void assertNotFound(ThrowingCallable call) {
        org.assertj.core.api.Assertions.assertThatThrownBy(call).isInstanceOf(NotFoundException.class);
    }

    private long count(String sql) {
        try (Connection c = RlsTestDatabase.fromConfig().openAsApp()) {
            c.setAutoCommit(false);
            try (PreparedStatement bind = c.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
                bind.setString(1, tenant.toString());
                bind.execute();
            }
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setObject(1, tenant.value());
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    return rs.getLong(1);
                }
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }
}
