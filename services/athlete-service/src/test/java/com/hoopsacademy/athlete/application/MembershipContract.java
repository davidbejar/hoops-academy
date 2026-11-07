package com.hoopsacademy.athlete.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * What the tenant filter's {@link AuthzContextResolver} answers in athlete, whatever its source (core's
 * /internal/authz or the local replica): the caller's roles and relations in an ACTIVE tenant, nothing for a
 * non-member or a member of a SUSPENDED / WITHDRAWN tenant (the filter then answers 404).
 */
public abstract class MembershipContract {

    /** A member as core knows it. Player teams belong to the own player, or to the first linked player. */
    public record Member(String subject, UUID personId, Set<TenantRole> roles, List<UUID> staffTeams,
            List<UUID> linkedPlayers, Optional<UUID> ownPlayer, List<UUID> playerTeams, ZoneId zone,
            List<UUID> historicStaffTeams) {

        /** A member without staff rows of ended seasons. */
        public Member(String subject, UUID personId, Set<TenantRole> roles, List<UUID> staffTeams,
                List<UUID> linkedPlayers, Optional<UUID> ownPlayer, List<UUID> playerTeams, ZoneId zone) {
            this(subject, personId, roles, staffTeams, linkedPlayers, ownPlayer, playerTeams, zone, List.of());
        }
    }

    public interface CoreFixture {

        void member(TenantId tenant, Member member, String tenantStatus);

        void noMember(TenantId tenant, String subject);
    }

    protected abstract AuthzContextResolver resolver();

    protected abstract CoreFixture core();

    /** The filter calls the resolver with the requested tenant bound. */
    protected abstract Optional<AuthzContext> resolveInTenant(TenantId tenant, String subject);

    protected TenantId tenant;

    @BeforeEach
    void freshTenant() {
        tenant = TenantId.random();
    }

    @Test
    void aCoachResolvesWithRolesStaffTeamsAndTheTenantsZone() {
        UUID team = UUID.randomUUID();
        Member coach = new Member("kc-" + UUID.randomUUID(), UUID.randomUUID(), Set.of(TenantRole.COACH, TenantRole.ADMIN),
                List.of(team), List.of(), Optional.empty(), List.of(), ZoneId.of("Asia/Jakarta"));
        core().member(tenant, coach, "ACTIVE");

        AuthzContext context = resolveInTenant(tenant, coach.subject()).orElseThrow();

        assertThat(context.subject()).isEqualTo(coach.subject());
        assertThat(context.personId()).isEqualTo(coach.personId());
        assertThat(context.tenantId()).isEqualTo(tenant);
        assertThat(context.roles()).containsExactlyInAnyOrder(TenantRole.COACH, TenantRole.ADMIN);
        assertThat(context.staffTeamIds()).containsExactly(team);
        assertThat(context.linkedPlayerIds()).isEmpty();
        assertThat(context.ownPlayerId()).isEmpty();
        assertThat(context.playerTeamIds()).isEmpty();
        assertThat(context.historicStaffTeamIds()).isEmpty();
        assertThat(context.timezone()).contains(ZoneId.of("Asia/Jakarta"));
    }

    @Test
    void aFormerCoachResolvesTheTeamsOfEndedSeasonsAsHistoryApartFromTodaysTeams() {
        UUID team = UUID.randomUUID();
        UUID pastTeam = UUID.randomUUID();
        Member coach = new Member("kc-" + UUID.randomUUID(), UUID.randomUUID(), Set.of(TenantRole.COACH), List.of(team),
                List.of(), Optional.empty(), List.of(), ZoneId.of("Asia/Jakarta"), List.of(pastTeam));
        core().member(tenant, coach, "ACTIVE");

        AuthzContext context = resolveInTenant(tenant, coach.subject()).orElseThrow();

        assertThat(context.staffTeamIds()).containsExactly(team);
        assertThat(context.historicStaffTeamIds()).containsExactly(pastTeam);
        assertThat(context.wasStaffOf(pastTeam)).isTrue();
        assertThat(context.isStaffOf(pastTeam)).isFalse();
    }

    @Test
    void aPlayerResolvesWithTheOwnPlayerAndItsTeams() {
        UUID player = UUID.randomUUID();
        UUID team = UUID.randomUUID();
        Member member = new Member("kc-" + UUID.randomUUID(), UUID.randomUUID(), Set.of(TenantRole.PLAYER), List.of(),
                List.of(), Optional.of(player), List.of(team), ZoneId.of("Europe/Madrid"));
        core().member(tenant, member, "ACTIVE");

        AuthzContext context = resolveInTenant(tenant, member.subject()).orElseThrow();

        assertThat(context.ownPlayerId()).contains(player);
        assertThat(context.isSelf(player)).isTrue();
        assertThat(context.playerTeamIds()).containsExactly(team);
    }

    @Test
    void aParentResolvesWithTheLinkedPlayersAndTheirTeams() {
        UUID child = UUID.randomUUID();
        UUID other = UUID.randomUUID();
        UUID team = UUID.randomUUID();
        Member parent = new Member("kc-" + UUID.randomUUID(), UUID.randomUUID(), Set.of(TenantRole.PARENT), List.of(),
                List.of(child, other), Optional.empty(), List.of(team), ZoneId.of("Europe/Madrid"));
        core().member(tenant, parent, "ACTIVE");

        AuthzContext context = resolveInTenant(tenant, parent.subject()).orElseThrow();

        assertThat(context.linkedPlayerIds()).containsExactlyInAnyOrder(child, other);
        assertThat(context.isGuardianOf(child)).isTrue();
        assertThat(context.playerTeamIds()).containsExactly(team);
    }

    @Test
    void aNonMemberResolvesToNothing() {
        core().noMember(tenant, "stranger");

        assertThat(resolveInTenant(tenant, "stranger")).isEmpty();
    }

    @Test
    void aMemberOfASuspendedOrWithdrawnTenantResolvesToNothing() {
        Member admin = new Member("kc-" + UUID.randomUUID(), UUID.randomUUID(), Set.of(TenantRole.ADMIN), List.of(),
                List.of(), Optional.empty(), List.of(), ZoneId.of("Europe/Madrid"));
        TenantId withdrawn = TenantId.random();
        core().member(tenant, admin, "SUSPENDED");
        core().member(withdrawn, admin, "WITHDRAWN");

        assertThat(resolveInTenant(tenant, admin.subject())).isEmpty();
        assertThat(resolveInTenant(withdrawn, admin.subject())).isEmpty();
    }

    @Test
    void theSameLoginResolvesPerTenant() {
        TenantId other = TenantId.random();
        Member inA = new Member("kc-" + UUID.randomUUID(), UUID.randomUUID(), Set.of(TenantRole.COACH), List.of(),
                List.of(), Optional.empty(), List.of(), ZoneId.of("Europe/Madrid"));
        Member inB = new Member(inA.subject(), UUID.randomUUID(), Set.of(TenantRole.PARENT), List.of(), List.of(),
                Optional.empty(), List.of(), ZoneId.of("Europe/Madrid"));
        core().member(tenant, inA, "ACTIVE");
        core().member(other, inB, "ACTIVE");

        assertThat(resolveInTenant(tenant, inA.subject()).orElseThrow().roles()).containsExactly(TenantRole.COACH);
        assertThat(resolveInTenant(other, inA.subject()).orElseThrow().personId()).isEqualTo(inB.personId());
    }
}
