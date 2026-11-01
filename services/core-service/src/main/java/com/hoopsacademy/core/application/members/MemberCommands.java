package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.application.shared.ChangedFields;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.domain.membership.LastAdminRule;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/** ADMIN changes to existing members: personal data, role set, deactivation. */
@ApplicationScoped
public class MemberCommands {

    private final TenantContext tenantContext;
    private final PersonRepository persons;
    private final PlayerRepository players;
    private final MembershipRepository memberships;
    private final MemberQueries queries;
    private final OutboxWriter outbox;
    private final AuthzCache authzCache;
    private final AuditLog audit;
    private final Clock clock;

    public MemberCommands(TenantContext tenantContext, PersonRepository persons, PlayerRepository players,
            MembershipRepository memberships, MemberQueries queries, OutboxWriter outbox, AuthzCache authzCache,
            AuditLog audit, Clock clock) {
        this.tenantContext = tenantContext;
        this.persons = persons;
        this.players = players;
        this.memberships = memberships;
        this.queries = queries;
        this.outbox = outbox;
        this.authzCache = authzCache;
        this.audit = audit;
        this.clock = clock;
    }

    @Transactional
    public MemberView updateData(PersonId id, PersonalDataChanges changes) {
        Person changed = queries.load(id).withData(changes);
        String email = changed.data().email();
        if (email != null && persons.emailTaken(email, Optional.of(id))) {
            throw new ConflictException("A member with this e-mail already exists", "EMAIL_TAKEN");
        }
        persons.update(changed);
        audit.record(AuditEvent.of("member.updated", "person", id.value(), Map.of("fields", new ChangedFields()
                .field("givenName", changes.givenName()).field("familyName", changes.familyName())
                .field("email", changes.email()).field("phone", changes.phone())
                .field("birthDate", changes.birthDate()).field("gender", changes.gender())
                .field("locale", changes.locale()).names())));
        return queries.view(changed);
    }

    @Transactional
    public MemberView replaceRoles(PersonId id, Set<TenantRole> roles) {
        Person current = queries.load(id);
        Person changed = current.withRoles(roles);
        if (current.active()) {
            LastAdminRule.checkRoleChange(current.roles(), changed.roles(), persons.countActiveAdmins());
        }
        persons.update(changed);
        if (changed.isPlayer() && players.findByPerson(id).isEmpty()) {
            players.create(id, PlayerStatus.ACTIVE);
        }
        membershipChanged(changed, "ROLES_REPLACED");
        audit.record(AuditEvent.of("member.roles_replaced", "person", id.value(), Map.of(
                "before", roleNames(current), "after", roleNames(changed))));
        return queries.view(changed);
    }

    @Transactional
    public MemberView deactivate(PersonId id) {
        Person current = queries.load(id);
        if (!current.active()) {
            return queries.view(current);
        }
        LastAdminRule.checkDeactivation(current.roles(), persons.countActiveAdmins());
        Person changed = current.deactivate(clock.instant());
        persons.update(changed);
        memberships.unregister(id);
        membershipChanged(changed, "DEACTIVATED");
        audit.record(AuditEvent.of("member.deactivated", "person", id.value(), Map.of("roles", roleNames(changed))));
        return queries.view(changed);
    }

    private static java.util.List<String> roleNames(Person person) {
        return person.roles().stream().map(Enum::name).sorted().toList();
    }

    private void membershipChanged(Person person, String change) {
        outbox.write(new OutboxEvent(tenantContext.requireTenantId(), "membership.changed", "person",
                person.id().value().toString(),
                Map.of("change", change, "active", person.active(),
                        "roles", person.roles().stream().map(Enum::name).sorted().toList())));
        authzCache.invalidate(tenantContext.requireTenantId());
    }
}
