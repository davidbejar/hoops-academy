package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.membership.InvitationStatus;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Map;
import java.util.Optional;

/**
 * The transactional half of adding a member (invite and first tenant ADMIN): person + roles (+ player), the login
 * link and membership index, the outbox event — and, LAST before commit, the temporary password of a login created
 * by this request (ADR-0024), so a Keycloak failure rolls the whole member back (the caller then deletes the created
 * login).
 */
@ApplicationScoped
public class MemberProvisioning {

    private final TenantContext tenantContext;
    private final PersonRepository persons;
    private final PlayerRepository players;
    private final AppUserRepository appUsers;
    private final MembershipRepository memberships;
    private final OutboxWriter outbox;
    private final TemporaryPasswords temporaryPasswords;
    private final AuthzCache authzCache;
    private final AuditLog audit;

    public MemberProvisioning(TenantContext tenantContext, PersonRepository persons, PlayerRepository players,
            AppUserRepository appUsers, MembershipRepository memberships, OutboxWriter outbox,
            TemporaryPasswords temporaryPasswords, AuthzCache authzCache, AuditLog audit) {
        this.tenantContext = tenantContext;
        this.persons = persons;
        this.players = players;
        this.appUsers = appUsers;
        this.memberships = memberships;
        this.outbox = outbox;
        this.temporaryPasswords = temporaryPasswords;
        this.authzCache = authzCache;
        this.audit = audit;
    }

    /** Fails fast (before any identity-provider call) when the e-mail already belongs to a member. */
    @Transactional
    public void requireEmailAvailable(String email) {
        if (email != null && persons.emailTaken(email, Optional.empty())) {
            throw new ConflictException("A member with this e-mail already exists", "EMAIL_TAKEN");
        }
    }

    @Transactional
    public WithTemporaryPassword<Person> create(Person draft, Optional<ProvisionedIdentity> login) {
        requireEmailAvailable(draft.data().email());
        Person person = login.map(identity -> linkLogin(draft, identity)).orElse(draft);
        persons.insert(person);
        if (person.isPlayer()) {
            players.create(person.id(), PlayerStatus.ACTIVE);
        }
        login.ifPresent(identity -> memberships.register(identity.subject(), person.id()));
        outbox.write(new OutboxEvent(tenantContext.requireTenantId(), "member.invited", "person",
                person.id().value().toString(),
                Map.of("personId", person.id().value().toString(), "roles", person.roles().stream().map(Enum::name).sorted().toList(),
                        "login", login.isPresent())));
        authzCache.invalidate(tenantContext.requireTenantId());
        audit.record(AuditEvent.of(AuditAction.MEMBER_INVITED, person.id().value(), Map.of(
                "roles", person.roles().stream().map(Enum::name).sorted().toList(), "login", login.isPresent())));
        return new WithTemporaryPassword<>(person, temporaryPasswords.forCreated(person.id(), login));
    }

    /** Links {@code identity} to the draft (409 when that login is already a member) and indexes the membership. */
    public Person attachLogin(Person draft, ProvisionedIdentity identity) {
        return linkLogin(draft, identity);
    }

    /** Registers the membership index row of a login linked by {@link #attachLogin} (after the person insert). */
    public void indexMembership(ProvisionedIdentity identity, Person person) {
        memberships.register(identity.subject(), person.id());
    }

    private Person linkLogin(Person draft, ProvisionedIdentity identity) {
        AppUser user = appUsers.findOrRegister(identity.subject(), draft.data().email());
        if (persons.loginLinked(user.id())) {
            throw new ConflictException("This login is already a member of the tenant", "LOGIN_ALREADY_MEMBER");
        }
        return draft.linkLogin(user.id(), identity.created() ? InvitationStatus.PENDING : InvitationStatus.ACCEPTED);
    }
}
