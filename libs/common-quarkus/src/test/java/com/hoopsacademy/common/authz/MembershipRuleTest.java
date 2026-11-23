package com.hoopsacademy.common.authz;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.MembershipRuleContract;
import com.hoopsacademy.common.testing.MembershipWorld;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/** The one membership rule (ADR-0066): the table of {@link MembershipRuleContract} plus what the reads cost. */
class MembershipRuleTest extends MembershipRuleContract {

    @Override
    protected Optional<AuthzContext> resolve(MembershipWorld world) {
        return MembershipRule.resolve(MembershipWorld.SUBJECT, MembershipWorld.TENANT, new WorldReads(world),
                MembershipWorld.CLOCK);
    }

    @Test
    void aMemberWithoutRelationsCostsNeitherAnAssignmentNorASeasonRead() {
        WorldReads reads = new WorldReads(MembershipWorld.member(TenantRole.ADMIN));

        assertThat(MembershipRule.resolve(MembershipWorld.SUBJECT, MembershipWorld.TENANT, reads,
                MembershipWorld.CLOCK)).isPresent();

        assertThat(reads.calls).containsExactly("tenant", "activeMember", "staffTeams");
    }

    @Test
    void ownAndLinkedPlayersAreReadOnlyWithTheirRolesAndTheirTeamsInOneRead() {
        WorldReads reads = new WorldReads(MembershipWorld.member(TenantRole.PLAYER, TenantRole.PARENT)
                .ownPlayer(MembershipWorld.OWN_PLAYER, MembershipWorld.CURRENT_TEAM)
                .guardianOf(MembershipWorld.CHILD, MembershipWorld.NEXT_SUMMER_TEAM)
                .staffOf(MembershipWorld.ENDED_TEAM));

        MembershipRule.resolve(MembershipWorld.SUBJECT, MembershipWorld.TENANT, reads, MembershipWorld.CLOCK);

        assertThat(reads.calls).containsExactly("tenant", "activeMember", "ownPlayer", "guardedPlayers", "staffTeams",
                "openValidTeamsOf", "seasonEnds");
        assertThat(reads.playersAsked).containsExactly(Set.of(MembershipWorld.OWN_PLAYER, MembershipWorld.CHILD));
        assertThat(reads.teamsAsked).containsExactly(Set.of(MembershipWorld.CURRENT_TEAM,
                MembershipWorld.NEXT_SUMMER_TEAM, MembershipWorld.ENDED_TEAM));
    }

    @Test
    void nothingAboutAPersonIsReadInATenantThatIsNotActive() {
        WorldReads reads = new WorldReads(MembershipWorld.member(TenantRole.ADMIN).tenant(TenantStatus.SUSPENDED));

        assertThat(MembershipRule.resolve(MembershipWorld.SUBJECT, MembershipWorld.TENANT, reads,
                MembershipWorld.CLOCK)).isEmpty();

        assertThat(reads.calls).containsExactly("tenant");
    }

    @Test
    void theRelationsOfAMemberAlreadyFoundAreReadInTheZoneGiven() {
        ZoneId utc = ZoneId.of("UTC");
        WorldReads reads = new WorldReads(MembershipWorld.member(TenantRole.COACH).staffOf(MembershipWorld.ENDED_TEAM));
        Member member = new Member(MembershipWorld.PERSON, Set.of(TenantRole.COACH));

        AuthzContext context = MembershipRule.contextOf(MembershipWorld.SUBJECT, MembershipWorld.TENANT, utc, member,
                reads, MembershipWorld.CLOCK);

        assertThat(context.staffTeamIds()).as("still 6 November in UTC").containsExactly(MembershipWorld.ENDED_TEAM);
        assertThat(context.historicStaffTeamIds()).isEmpty();
        assertThat(context.timezone()).contains(utc);
        assertThat(reads.calls).doesNotContain("tenant", "activeMember");
    }

    @Test
    void aMemberKeepsACopyOfItsRoles() {
        Set<TenantRole> roles = EnumSet.of(TenantRole.COACH);
        Member member = new Member(MembershipWorld.PERSON, roles);
        roles.add(TenantRole.ADMIN);

        assertThat(member.roles()).containsExactly(TenantRole.COACH);
        assertThat(member.has(TenantRole.COACH)).isTrue();
        assertThat(member.has(TenantRole.ADMIN)).isFalse();
        assertThatThrownBy(() -> new Member(null, Set.of())).isInstanceOf(NullPointerException.class);
    }

    @Test
    void onlyAnActiveTenantHasMembers() {
        ZoneId zone = MembershipWorld.ZONE;
        assertThat(new MembershipReads.TenantState(TenantStatus.ACTIVE, zone).active()).isTrue();
        assertThat(new MembershipReads.TenantState(TenantStatus.SUSPENDED, zone).active()).isFalse();
        assertThat(new MembershipReads.TenantState(TenantStatus.WITHDRAWN, zone).active()).isFalse();
    }

    /** The reads of a store holding the world, recording which ones the rule makes. */
    private static final class WorldReads implements MembershipReads {

        private final MembershipWorld world;
        final List<String> calls = new ArrayList<>();
        final List<Set<UUID>> playersAsked = new ArrayList<>();
        final List<Set<UUID>> teamsAsked = new ArrayList<>();

        WorldReads(MembershipWorld world) {
            this.world = world;
        }

        @Override
        public Optional<TenantState> tenant(TenantId tenant) {
            calls.add("tenant");
            return world.tenantStatus().filter(status -> tenant.equals(MembershipWorld.TENANT))
                    .map(status -> new TenantState(status, MembershipWorld.ZONE));
        }

        @Override
        public Optional<Member> activeMember(String subject) {
            calls.add("activeMember");
            return world.memberRoles().filter(roles -> subject.equals(MembershipWorld.SUBJECT))
                    .map(roles -> new Member(MembershipWorld.PERSON, roles));
        }

        @Override
        public Optional<UUID> ownPlayer(UUID personId) {
            calls.add("ownPlayer");
            return world.ownPlayer().filter(player -> personId.equals(MembershipWorld.PERSON));
        }

        @Override
        public Set<UUID> guardedPlayers(UUID personId) {
            calls.add("guardedPlayers");
            return personId.equals(MembershipWorld.PERSON) ? world.guardedPlayers() : Set.of();
        }

        @Override
        public Set<UUID> staffTeams(UUID personId) {
            calls.add("staffTeams");
            return personId.equals(MembershipWorld.PERSON) ? world.staffTeams() : Set.of();
        }

        @Override
        public Set<UUID> openValidTeamsOf(Set<UUID> players) {
            calls.add("openValidTeamsOf");
            playersAsked.add(Set.copyOf(players));
            Set<UUID> teams = new HashSet<>();
            players.forEach(player -> teams.addAll(world.openValidTeamsOf(player)));
            return teams;
        }

        @Override
        public Map<UUID, LocalDate> seasonEnds(Set<UUID> teams) {
            calls.add("seasonEnds");
            teamsAsked.add(Set.copyOf(teams));
            return teams.stream().filter(team -> world.seasonEnd(team).isPresent())
                    .collect(Collectors.toMap(team -> team, team -> world.seasonEnd(team).orElseThrow()));
        }
    }
}
