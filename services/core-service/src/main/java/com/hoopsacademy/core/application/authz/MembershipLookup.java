package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.authz.Member;
import com.hoopsacademy.common.authz.MemberRelations;
import com.hoopsacademy.common.authz.MembershipRule;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.Optional;

/**
 * Reads a subject's membership in the BOUND tenant from the database: the tenant profile and the subject's active
 * person, then the context through common's {@link MembershipRule} (ADR-0066) over core's own tables: roles, relations
 * (staff teams, linked players, own player, teams of those players), the tenant's time zone, and the historic staff
 * teams of ended seasons (read-only history, ADR-0042). The tenant's lifecycle status is kept next to the context:
 * the tenant filter and the callers of {@code /internal/authz} treat a non-ACTIVE tenant as "not a member".
 */
@ApplicationScoped
public class MembershipLookup {

    private final TenantContext tenantContext;
    private final TenantProfileRepository profiles;
    private final PersonRepository persons;
    private final MemberRelations relations;
    private final Clock clock;

    public MembershipLookup(TenantContext tenantContext, TenantProfileRepository profiles, PersonRepository persons,
            PlayerRepository players, GuardianLinkRepository guardianLinks, TeamStaffRepository staff,
            TeamPlayerRepository assignments, TeamRepository teams, Clock clock) {
        this.tenantContext = tenantContext;
        this.profiles = profiles;
        this.persons = persons;
        this.relations = new CoreMemberRelations(players, guardianLinks, staff, assignments, teams);
        this.clock = clock;
    }

    /** A membership with the person and the tenant profile it was read from (GET/PATCH /me need both). */
    public record Found(MemberAuthz authz, Person person, TenantProfile tenant) {}

    /** @return empty when the tenant does not exist or the subject has no active person in it */
    @Transactional
    public Optional<MemberAuthz> find(String subject) {
        return findWithPerson(subject).map(Found::authz);
    }

    /** Like {@link #find}, keeping the person and the profile it loaded. */
    @Transactional
    public Optional<Found> findWithPerson(String subject) {
        Optional<TenantProfile> tenant = profiles.findCurrent();
        if (tenant.isEmpty()) {
            return Optional.empty();
        }
        return persons.findActiveByLogin(subject).map(person -> new Found(new MemberAuthz(
                MembershipRule.contextOf(subject, tenantContext.requireTenantId(), tenant.get().timezone(),
                        new Member(person.id().value(), person.roles()), relations, clock),
                tenant.get().status()), person, tenant.get()));
    }
}
