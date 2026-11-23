package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.testing.MembershipRuleContract;
import com.hoopsacademy.common.testing.MembershipWorld;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/** The membership rule table (ADR-0066) against game's replica resolver on an in-memory replica. */
class ReplicaAuthzResolverRuleTest extends MembershipRuleContract {

    @Override
    protected Optional<AuthzContext> resolve(MembershipWorld world) {
        FakeRosterQueries replica = new FakeRosterQueries();
        world.tenantStatus().ifPresent(status -> replica.tenants.put(MembershipWorld.TENANT,
                new ReplicaTenant(status, MembershipWorld.ZONE)));
        world.memberRoles().ifPresent(roles -> replica.persons.put(MembershipWorld.SUBJECT,
                new ReplicaPerson(MembershipWorld.PERSON, roles)));
        world.ownPlayer().ifPresent(player -> replica.ownPlayers.put(MembershipWorld.PERSON, PlayerId.of(player)));
        replica.links.put(MembershipWorld.PERSON,
                world.guardedPlayers().stream().map(PlayerId::of).collect(Collectors.toSet()));
        replica.staff.put(MembershipWorld.PERSON, teams(world.staffTeams()));
        Stream.concat(world.ownPlayer().stream(), world.guardedPlayers().stream()).forEach(player ->
                replica.assignments.put(PlayerId.of(player), teams(world.openValidTeamsOf(player))));
        world.knownTeams().forEach(team -> replica.teams.put(TeamId.of(team), new ReplicaTeam(TeamId.of(team),
                SeasonId.of(UUID.randomUUID()), "Team", world.seasonEnd(team).orElseThrow())));
        return new ReplicaAuthzResolver(replica, MembershipWorld.CLOCK).resolve(MembershipWorld.SUBJECT,
                MembershipWorld.TENANT);
    }

    private static Set<TeamId> teams(Set<UUID> ids) {
        return ids.stream().map(TeamId::of).collect(Collectors.toSet());
    }
}
