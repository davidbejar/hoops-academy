package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.StaffTeamsQuery;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Reads a subject's membership in the BOUND tenant from the database: roles, relations (staff teams, linked players,
 * own player, teams of those players), the tenant's time zone and lifecycle status.
 */
@ApplicationScoped
public class MembershipLookup {

    private final TenantContext tenantContext;
    private final TenantProfileRepository profiles;
    private final PersonRepository persons;
    private final PlayerRepository players;
    private final GuardianLinkRepository guardianLinks;
    private final StaffTeamsQuery staffTeams;
    private final TeamPlayerRepository assignments;

    public MembershipLookup(TenantContext tenantContext, TenantProfileRepository profiles, PersonRepository persons,
            PlayerRepository players, GuardianLinkRepository guardianLinks, StaffTeamsQuery staffTeams,
            TeamPlayerRepository assignments) {
        this.tenantContext = tenantContext;
        this.profiles = profiles;
        this.persons = persons;
        this.players = players;
        this.guardianLinks = guardianLinks;
        this.staffTeams = staffTeams;
        this.assignments = assignments;
    }

    /** @return empty when the tenant does not exist or the subject has no active person in it */
    @Transactional
    public Optional<MemberAuthz> find(String subject) {
        Optional<TenantProfile> tenant = profiles.findCurrent();
        if (tenant.isEmpty()) {
            return Optional.empty();
        }
        return persons.findActiveByLogin(subject)
                .map(person -> new MemberAuthz(contextOf(subject, person, tenant.get()), tenant.get().status()));
    }

    private AuthzContext contextOf(String subject, Person person, TenantProfile tenant) {
        Optional<UUID> ownPlayer = person.isPlayer()
                ? players.findByPerson(person.id()).map(PlayerId::value)
                : Optional.empty();
        Set<UUID> linkedPlayers = person.roles().contains(TenantRole.PARENT)
                ? guardianLinks.playersOf(person.id()).stream().map(PlayerId::value).collect(Collectors.toSet())
                : Set.of();
        return new AuthzContext(subject, person.id().value(), tenantContext.requireTenantId(), person.roles(),
                staffTeams.staffTeamsOf(person.id()), linkedPlayers, ownPlayer, teamsOf(ownPlayer, linkedPlayers),
                Optional.of(tenant.timezone()));
    }

    /** Teams with an open, valid assignment of the own or a linked player (what the roster endpoint lists). */
    private Set<UUID> teamsOf(Optional<UUID> ownPlayer, Set<UUID> linkedPlayers) {
        Set<UUID> playerIds = new HashSet<>(linkedPlayers);
        ownPlayer.ifPresent(playerIds::add);
        if (playerIds.isEmpty()) {
            return Set.of();
        }
        return assignments.openOfPlayers(playerIds.stream().map(PlayerId::new).toList()).stream()
                .filter(TeamPlayer::isValid)
                .map(assignment -> assignment.team().value())
                .collect(Collectors.toSet());
    }
}
