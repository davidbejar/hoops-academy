package com.hoopsacademy.game.application.replica;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The replica's membership rules (the same as core's {@code /internal/authz}), on an in-memory replica. */
class ReplicaAuthzResolverTest {

    private static final TenantId TENANT = TenantId.random();
    private static final ZoneId JAKARTA = ZoneId.of("Asia/Jakarta");
    /** 20:00 UTC on 6 November is already 7 November in Jakarta (UTC+7). */
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-11-06T20:00:00Z"), ZoneOffset.UTC);
    private static final UUID PERSON = UUID.randomUUID();
    private static final String SUBJECT = "sub-mia";

    private final FakeRosterQueries replica = new FakeRosterQueries();
    private final ReplicaAuthzResolver resolver = new ReplicaAuthzResolver(replica, CLOCK);

    private final TeamId endedInJakarta = team(LocalDate.parse("2026-11-06"));
    private final TeamId endsTodayInJakarta = team(LocalDate.parse("2026-11-07"));

    @Test
    void seasonsEndInTheAcademysTimeZone() {
        member(TenantRole.COACH);
        replica.staff.put(PERSON, Set.of(endedInJakarta, endsTodayInJakarta, TeamId.of(UUID.randomUUID())));

        AuthzContext context = resolver.resolve(SUBJECT, TENANT).orElseThrow();

        assertThat(context.staffTeamIds()).containsExactly(endsTodayInJakarta.value());
        assertThat(context.timezone()).contains(JAKARTA);
        assertThat(context.subject()).isEqualTo(SUBJECT);
        assertThat(context.personId()).isEqualTo(PERSON);
        assertThat(context.tenantId()).isEqualTo(TENANT);
        assertThat(context.roles()).containsExactly(TenantRole.COACH);
    }

    @Test
    void theOwnPlayerCountsWithThePlayerRoleOnly() {
        PlayerId own = PlayerId.of(UUID.randomUUID());
        replica.ownPlayers.put(PERSON, own);
        replica.assignments.put(own, Set.of(endsTodayInJakarta, endedInJakarta));

        member(TenantRole.PLAYER);
        AuthzContext player = resolver.resolve(SUBJECT, TENANT).orElseThrow();
        assertThat(player.ownPlayerId()).contains(own.value());
        assertThat(player.playerTeamIds()).containsExactly(endsTodayInJakarta.value());

        member(TenantRole.COACH);
        AuthzContext coach = resolver.resolve(SUBJECT, TENANT).orElseThrow();
        assertThat(coach.ownPlayerId()).isEmpty();
        assertThat(coach.playerTeamIds()).isEmpty();
    }

    @Test
    void linkedPlayersCountWithTheParentRoleOnly() {
        PlayerId child = PlayerId.of(UUID.randomUUID());
        replica.links.put(PERSON, Set.of(child));
        replica.assignments.put(child, Set.of(endsTodayInJakarta));

        member(TenantRole.PARENT);
        AuthzContext parent = resolver.resolve(SUBJECT, TENANT).orElseThrow();
        assertThat(parent.linkedPlayerIds()).containsExactly(child.value());
        assertThat(parent.playerTeamIds()).containsExactly(endsTodayInJakarta.value());

        member(TenantRole.ADMIN);
        AuthzContext admin = resolver.resolve(SUBJECT, TENANT).orElseThrow();
        assertThat(admin.linkedPlayerIds()).isEmpty();
        assertThat(admin.playerTeamIds()).isEmpty();
    }

    @Test
    void playerTeamsAreTheTeamsOfTheOwnAndTheLinkedPlayers() {
        PlayerId own = PlayerId.of(UUID.randomUUID());
        PlayerId child = PlayerId.of(UUID.randomUUID());
        TeamId other = team(LocalDate.parse("2027-06-30"));
        replica.ownPlayers.put(PERSON, own);
        replica.links.put(PERSON, Set.of(child));
        replica.assignments.put(own, Set.of(endsTodayInJakarta));
        replica.assignments.put(child, Set.of(other));
        member(TenantRole.PLAYER, TenantRole.PARENT);

        assertThat(resolver.resolve(SUBJECT, TENANT).orElseThrow().playerTeamIds())
                .containsExactlyInAnyOrder(endsTodayInJakarta.value(), other.value());
    }

    @Test
    void onlyMembersOfAnActiveTenantResolve() {
        member(TenantRole.ADMIN);
        assertThat(resolver.resolve(SUBJECT, TENANT)).isPresent();
        assertThat(resolver.resolve("someone-else", TENANT)).isEmpty();

        replica.tenants.put(TENANT, new ReplicaTenant(TenantStatus.SUSPENDED, JAKARTA));
        assertThat(resolver.resolve(SUBJECT, TENANT)).isEmpty();

        replica.tenants.put(TENANT, new ReplicaTenant(TenantStatus.WITHDRAWN, JAKARTA));
        assertThat(resolver.resolve(SUBJECT, TENANT)).isEmpty();

        replica.tenants.remove(TENANT);
        assertThat(resolver.resolve(SUBJECT, TENANT)).isEmpty();
    }

    private void member(TenantRole... roles) {
        replica.tenants.put(TENANT, new ReplicaTenant(TenantStatus.ACTIVE, JAKARTA));
        replica.persons.put(SUBJECT, new ReplicaPerson(PERSON, Set.of(roles)));
    }

    private TeamId team(LocalDate seasonEnd) {
        TeamId id = TeamId.of(UUID.randomUUID());
        replica.teams.put(id, new ReplicaTeam(id, SeasonId.of(UUID.randomUUID()), "Team", seasonEnd));
        return id;
    }
}
