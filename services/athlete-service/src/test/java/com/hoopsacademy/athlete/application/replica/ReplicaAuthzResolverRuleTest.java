package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.MembershipRuleContract;
import com.hoopsacademy.common.testing.MembershipWorld;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/** The membership rule table (ADR-0066) against athlete's replica resolver on in-memory replica reads. */
class ReplicaAuthzResolverRuleTest extends MembershipRuleContract {

    @Override
    protected Optional<AuthzContext> resolve(MembershipWorld world) {
        return new ReplicaAuthzResolver(new WorldReads(world), MembershipWorld.CLOCK).resolve(MembershipWorld.SUBJECT,
                MembershipWorld.TENANT);
    }

    /** The replica's reads answering what the world holds (removed rows are simply absent). */
    private record WorldReads(MembershipWorld world) implements ReplicaMembershipReads {

        @Override
        public Optional<TenantState> tenant(TenantId tenant) {
            return world.tenantStatus().filter(status -> tenant.equals(MembershipWorld.TENANT))
                    .map(status -> new TenantState(status.name(), MembershipWorld.ZONE));
        }

        @Override
        public Optional<Member> activeMemberWithLogin(String subject) {
            return world.memberRoles().filter(roles -> subject.equals(MembershipWorld.SUBJECT))
                    .map(roles -> new Member(new PersonId(MembershipWorld.PERSON), roles));
        }

        @Override
        public Optional<PlayerId> playerOf(PersonId person) {
            return world.ownPlayer().map(PlayerId::new);
        }

        @Override
        public Set<PlayerId> guardedPlayers(PersonId guardian) {
            return world.guardedPlayers().stream().map(PlayerId::new).collect(Collectors.toSet());
        }

        @Override
        public Set<TeamId> staffTeams(PersonId person) {
            return world.staffTeams().stream().map(TeamId::new).collect(Collectors.toSet());
        }

        @Override
        public Set<TeamId> openValidTeamsOf(Collection<PlayerId> players) {
            return players.stream().flatMap(player -> world.openValidTeamsOf(player.value()).stream())
                    .map(TeamId::new).collect(Collectors.toSet());
        }

        @Override
        public Map<TeamId, LocalDate> seasonEnds(Collection<TeamId> teams) {
            return teams.stream().filter(team -> world.seasonEnd(team.value()).isPresent())
                    .collect(Collectors.toMap(team -> team, team -> world.seasonEnd(team.value()).orElseThrow()));
        }
    }
}
