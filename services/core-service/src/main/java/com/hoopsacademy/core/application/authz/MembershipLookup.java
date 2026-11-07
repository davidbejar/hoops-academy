package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.StaffTeamsQuery;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.shared.TenantCalendar;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Reads a subject's membership in the BOUND tenant from the database: roles, relations (staff teams, linked players,
 * own player, teams of those players), the tenant's time zone and lifecycle status. Teams whose season has ended (in
 * the academy's time zone) are left out of both team sets, even while a staff row or an assignment is still open
 * (WP58): the summary grants today's access, past seasons are history. The staff rows of those teams become the
 * historic staff teams (read-only history, ADR-0042).
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
    private final TeamRepository teams;
    private final Clock clock;

    public MembershipLookup(TenantContext tenantContext, TenantProfileRepository profiles, PersonRepository persons,
            PlayerRepository players, GuardianLinkRepository guardianLinks, StaffTeamsQuery staffTeams,
            TeamPlayerRepository assignments, TeamRepository teams, Clock clock) {
        this.tenantContext = tenantContext;
        this.profiles = profiles;
        this.persons = persons;
        this.players = players;
        this.guardianLinks = guardianLinks;
        this.staffTeams = staffTeams;
        this.assignments = assignments;
        this.teams = teams;
        this.clock = clock;
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
        Set<UUID> staffTeamIds = staffTeams.staffTeamsOf(person.id());
        Set<UUID> playerTeamIds = teamsOf(ownPlayer, linkedPlayers);
        Set<UUID> notEnded = seasonNotEnded(staffTeamIds, playerTeamIds, TenantCalendar.today(clock.instant(),
                tenant.timezone()));
        return new AuthzContext(subject, person.id().value(), tenantContext.requireTenantId(), person.roles(),
                retain(staffTeamIds, notEnded), linkedPlayers, ownPlayer, retain(playerTeamIds, notEnded),
                Optional.of(tenant.timezone()), ended(staffTeamIds, notEnded));
    }

    /** One query for both team sets. */
    private Set<UUID> seasonNotEnded(Set<UUID> staffTeamIds, Set<UUID> playerTeamIds, LocalDate today) {
        Set<TeamId> candidates = new HashSet<>();
        staffTeamIds.forEach(id -> candidates.add(new TeamId(id)));
        playerTeamIds.forEach(id -> candidates.add(new TeamId(id)));
        return teams.seasonNotEnded(candidates, today).stream().map(TeamId::value).collect(Collectors.toSet());
    }

    private static Set<UUID> retain(Set<UUID> teamIds, Set<UUID> notEnded) {
        return teamIds.stream().filter(notEnded::contains).collect(Collectors.toSet());
    }

    /** Every staff row points to an existing team (foreign key), so a staff team not "not ended" has ended. */
    private static Set<UUID> ended(Set<UUID> teamIds, Set<UUID> notEnded) {
        return teamIds.stream().filter(id -> !notEnded.contains(id)).collect(Collectors.toSet());
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
