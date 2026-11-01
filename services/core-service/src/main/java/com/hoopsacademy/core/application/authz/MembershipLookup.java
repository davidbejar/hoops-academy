package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.StaffTeamsQuery;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/** Reads a subject's membership in the BOUND tenant from the database (roles, relations, tenant status). */
@ApplicationScoped
public class MembershipLookup {

    private final TenantContext tenantContext;
    private final TenantProfileRepository profiles;
    private final PersonRepository persons;
    private final PlayerRepository players;
    private final GuardianLinkRepository guardianLinks;
    private final StaffTeamsQuery staffTeams;

    public MembershipLookup(TenantContext tenantContext, TenantProfileRepository profiles, PersonRepository persons,
            PlayerRepository players, GuardianLinkRepository guardianLinks, StaffTeamsQuery staffTeams) {
        this.tenantContext = tenantContext;
        this.profiles = profiles;
        this.persons = persons;
        this.players = players;
        this.guardianLinks = guardianLinks;
        this.staffTeams = staffTeams;
    }

    /** @return empty when the tenant does not exist or the subject has no active person in it */
    @Transactional
    public Optional<MemberAuthz> find(String subject) {
        Optional<TenantProfile> tenant = profiles.findCurrent();
        if (tenant.isEmpty()) {
            return Optional.empty();
        }
        return persons.findActiveByLogin(subject)
                .map(person -> new MemberAuthz(contextOf(subject, person), tenant.get().status()));
    }

    private AuthzContext contextOf(String subject, Person person) {
        Optional<UUID> ownPlayer = person.isPlayer()
                ? players.findByPerson(person.id()).map(PlayerId::value)
                : Optional.empty();
        Set<UUID> linkedPlayers = person.roles().contains(TenantRole.PARENT)
                ? guardianLinks.playersOf(person.id()).stream().map(PlayerId::value).collect(Collectors.toSet())
                : Set.of();
        return new AuthzContext(subject, person.id().value(), tenantContext.requireTenantId(), person.roles(),
                staffTeams.staffTeamsOf(person.id()), linkedPlayers, ownPlayer);
    }
}
