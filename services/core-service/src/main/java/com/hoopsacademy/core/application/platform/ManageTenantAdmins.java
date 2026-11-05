package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.members.InviteMember;
import com.hoopsacademy.core.application.members.InviteMemberCommand;
import com.hoopsacademy.core.application.members.IssueTemporaryPassword;
import com.hoopsacademy.core.application.members.LoginEmailSync.SharedLogin;
import com.hoopsacademy.core.application.members.LoginProvisioning;
import com.hoopsacademy.core.application.members.MemberCommands;
import com.hoopsacademy.core.application.members.MemberProvisioning;
import com.hoopsacademy.core.application.members.MemberQueries;
import com.hoopsacademy.core.application.members.MemberView;
import com.hoopsacademy.core.application.members.TemporaryPasswords;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PersonRepository.MemberFilter;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.application.shared.ChangedFields;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.EnumSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Supplier;

/**
 * The super admin manages the administrators of any tenant (ADR-0023). The registry check (404 / 409
 * {@code TENANT_WITHDRAWN}) runs on the platform datasource; every tenant read and write runs as core_app inside
 * {@code TenantScope.runAs(tenant)} and reuses the academy-admin use cases (invite saga, role change, deactivation,
 * e-mail sync, last-admin rule, temporary passwords). Audit rows go to the tenant's trail with the super admin's
 * subject as actor.
 */
@ApplicationScoped
public class ManageTenantAdmins {

    /**
     * The outcome of {@link #add}: the administrator, whether a new member was invited (else promoted) and the
     * temporary password of a login created by this call (ADR-0024).
     */
    public record AddedAdmin(MemberView admin, boolean invited, Optional<TemporaryPassword> temporaryPassword) {}

    private static final MemberFilter ACTIVE_ADMINS =
            new MemberFilter(Optional.of(TenantRole.ADMIN), Optional.of(true), Optional.empty());

    private final PlatformTenantQueries registry;
    private final TenantScope tenantScope;
    private final PersonRepository persons;
    private final MemberQueries queries;
    private final MemberCommands commands;
    private final InviteMember inviteMember;
    private final LoginProvisioning logins;
    private final MemberProvisioning provisioning;
    private final TemporaryPasswords temporaryPasswords;
    private final IssueTemporaryPassword issueTemporaryPassword;
    private final AuditLog audit;

    public ManageTenantAdmins(PlatformTenantQueries registry, TenantScope tenantScope, PersonRepository persons,
            MemberQueries queries, MemberCommands commands, InviteMember inviteMember, LoginProvisioning logins,
            MemberProvisioning provisioning, TemporaryPasswords temporaryPasswords,
            IssueTemporaryPassword issueTemporaryPassword, AuditLog audit) {
        this.registry = registry;
        this.tenantScope = tenantScope;
        this.persons = persons;
        this.queries = queries;
        this.commands = commands;
        this.inviteMember = inviteMember;
        this.logins = logins;
        this.provisioning = provisioning;
        this.temporaryPasswords = temporaryPasswords;
        this.issueTemporaryPassword = issueTemporaryPassword;
        this.audit = audit;
    }

    public PageResult<MemberView> list(TenantId tenant, PageRequest page) {
        return inTenant(tenant, () -> queries.list(ACTIVE_ADMINS, page));
    }

    /** Promotes the active member with this e-mail (200) or invites a new member as ADMIN (201). */
    public AddedAdmin add(TenantId tenant, PersonalData admin) {
        return inTenant(tenant, () -> persons.findByEmail(admin.email())
                .map(this::promote)
                .orElseGet(() -> invite(admin)));
    }

    public MemberView update(TenantId tenant, PersonId id, PersonalDataChanges changes) {
        return inTenant(tenant, () -> {
            requireActiveAdmin(id);
            audit.record(AuditEvent.of(AuditAction.ADMIN_UPDATED, id.value(), Map.of("fields", new ChangedFields()
                    .field("givenName", changes.givenName()).field("familyName", changes.familyName())
                    .field("email", changes.email()).names())));
            return commands.updateData(id, changes, SharedLogin.SYNC);
        });
    }

    /** Drops the ADMIN role, deactivating a person who had no other role; never the last admin (409). */
    public void remove(TenantId tenant, PersonId id) {
        inTenant(tenant, () -> {
            Person admin = requireActiveAdmin(id);
            Set<TenantRole> otherRoles = otherRoles(admin);
            if (otherRoles.isEmpty()) {
                commands.deactivate(id);
            } else {
                commands.replaceRoles(id, otherRoles);
            }
            audit.record(AuditEvent.of(AuditAction.ADMIN_REMOVED, id.value(),
                    Map.of("membershipDeactivated", otherRoles.isEmpty())));
            return null;
        });
    }

    /**
     * A new temporary password for an administrator whose invitation is still pending (ADR-0024); also repairs a
     * pending login without any password. The super admin may reset a login shared with another tenant.
     */
    public WithTemporaryPassword<MemberView> issueTemporaryPassword(TenantId tenant, PersonId id) {
        return inTenant(tenant, () -> {
            requireActiveAdmin(id);
            audit.record(AuditEvent.of(AuditAction.ADMIN_TEMPORARY_PASSWORD_ISSUED, id.value()));
            return issueTemporaryPassword.handle(id, SharedLogin.SYNC);
        });
    }

    public static Set<TenantRole> otherRoles(Person person) {
        Set<TenantRole> others = EnumSet.noneOf(TenantRole.class);
        others.addAll(person.roles());
        others.remove(TenantRole.ADMIN);
        return others;
    }

    private <T> T inTenant(TenantId tenant, Supplier<T> work) {
        registry.get(tenant).requireManageable();
        return tenantScope.runAs(tenant, work);
    }

    private AddedAdmin promote(Person member) {
        if (!member.active()) {
            throw new ConflictException("A former member of the academy uses this e-mail address", "EMAIL_TAKEN");
        }
        if (member.isAdmin()) {
            return new AddedAdmin(queries.view(member), false, Optional.empty());
        }
        Set<TenantRole> roles = EnumSet.of(TenantRole.ADMIN);
        roles.addAll(member.roles());
        commands.replaceRoles(member.id(), roles);
        audit.record(AuditEvent.of(AuditAction.ADMIN_ADDED, member.id().value(), Map.of("invited", false)));
        Optional<TemporaryPassword> password = member.userId() == null
                ? giveLogin(persons.find(member.id()).orElseThrow())
                : Optional.empty();
        return new AddedAdmin(queries.get(member.id()), false, password);
    }

    private AddedAdmin invite(PersonalData admin) {
        WithTemporaryPassword<MemberView> invited =
                inviteMember.handle(new InviteMemberCommand(admin, Set.of(TenantRole.ADMIN), true));
        audit.record(AuditEvent.of(AuditAction.ADMIN_ADDED, invited.value().person().id().value(),
                Map.of("invited", true)));
        return new AddedAdmin(invited.value(), true, invited.temporaryPassword());
    }

    /**
     * A promoted member without a login gets one (the invitation saga; a created login's temporary password is the
     * last step).
     */
    private Optional<TemporaryPassword> giveLogin(Person member) {
        PersonalData data = member.data();
        ProvisionedIdentity login = logins.provision(
                new NewIdentity(data.email(), data.givenName(), data.familyName(), data.locale()));
        return logins.compensateOnFailure(login, () -> {
            Person linked = provisioning.attachLogin(member, login);
            persons.update(linked);
            provisioning.indexMembership(login, linked);
            return temporaryPasswords.forCreated(linked.id(), Optional.of(login));
        });
    }

    private Person requireActiveAdmin(PersonId id) {
        return persons.find(id).filter(person -> person.active() && person.isAdmin())
                .orElseThrow(() -> new NotFoundException("Administrator not found"));
    }
}
