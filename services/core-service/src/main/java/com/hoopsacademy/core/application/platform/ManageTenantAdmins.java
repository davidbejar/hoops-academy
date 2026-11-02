package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.members.InviteMember;
import com.hoopsacademy.core.application.members.InviteMemberCommand;
import com.hoopsacademy.core.application.members.LoginEmailSync.SharedLogin;
import com.hoopsacademy.core.application.members.LoginProvisioning;
import com.hoopsacademy.core.application.members.MemberCommands;
import com.hoopsacademy.core.application.members.MemberProvisioning;
import com.hoopsacademy.core.application.members.MemberQueries;
import com.hoopsacademy.core.application.members.MemberView;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PersonRepository.MemberFilter;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.application.shared.ChangedFields;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.InvitationStatus;
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
 * e-mail sync, last-admin rule). Audit rows go to the tenant's trail with the super admin's subject as actor.
 */
@ApplicationScoped
public class ManageTenantAdmins {

    public static final String INVITATION_NOT_PENDING = "INVITATION_NOT_PENDING";

    /** The outcome of {@link #add}: the administrator and whether a new member was invited (else promoted). */
    public record AddedAdmin(MemberView admin, boolean invited) {}

    private static final MemberFilter ACTIVE_ADMINS =
            new MemberFilter(Optional.of(TenantRole.ADMIN), Optional.of(true), Optional.empty());

    private final PlatformTenantQueries registry;
    private final TenantScope tenantScope;
    private final PersonRepository persons;
    private final AppUserRepository appUsers;
    private final MemberQueries queries;
    private final MemberCommands commands;
    private final InviteMember inviteMember;
    private final LoginProvisioning logins;
    private final MemberProvisioning provisioning;
    private final IdentityProviderPort identityProvider;
    private final AuditLog audit;

    public ManageTenantAdmins(PlatformTenantQueries registry, TenantScope tenantScope, PersonRepository persons,
            AppUserRepository appUsers, MemberQueries queries, MemberCommands commands, InviteMember inviteMember,
            LoginProvisioning logins, MemberProvisioning provisioning, IdentityProviderPort identityProvider,
            AuditLog audit) {
        this.registry = registry;
        this.tenantScope = tenantScope;
        this.persons = persons;
        this.appUsers = appUsers;
        this.queries = queries;
        this.commands = commands;
        this.inviteMember = inviteMember;
        this.logins = logins;
        this.provisioning = provisioning;
        this.identityProvider = identityProvider;
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
            audit.record(AuditEvent.of("admin.updated", "person", id.value(), Map.of("fields", new ChangedFields()
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
            audit.record(AuditEvent.of("admin.removed", "person", id.value(),
                    Map.of("membershipDeactivated", otherRoles.isEmpty())));
            return null;
        });
    }

    /** Sends the account-setup e-mail again while the invitation is pending (the e-mail is the last step). */
    public MemberView resendInvitation(TenantId tenant, PersonId id) {
        return inTenant(tenant, () -> {
            Person admin = requireActiveAdmin(id);
            if (admin.invitationStatus() != InvitationStatus.PENDING) {
                throw new ConflictException("Only a pending invitation can be sent again", INVITATION_NOT_PENDING);
            }
            String subject = appUsers.findById(admin.userId())
                    .orElseThrow(() -> new IllegalStateException("Pending admin " + id + " has no login")).subject();
            audit.record(AuditEvent.of("admin.invitation_resent", "person", id.value()));
            identityProvider.sendAccountSetupEmail(subject);
            return queries.view(admin);
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
            return new AddedAdmin(queries.view(member), false);
        }
        Set<TenantRole> roles = EnumSet.of(TenantRole.ADMIN);
        roles.addAll(member.roles());
        commands.replaceRoles(member.id(), roles);
        audit.record(AuditEvent.of("admin.added", "person", member.id().value(), Map.of("invited", false)));
        if (member.userId() == null) {
            giveLogin(persons.find(member.id()).orElseThrow());
        }
        return new AddedAdmin(queries.get(member.id()), false);
    }

    private AddedAdmin invite(PersonalData admin) {
        MemberView invited = inviteMember.handle(new InviteMemberCommand(admin, Set.of(TenantRole.ADMIN), true));
        audit.record(AuditEvent.of("admin.added", "person", invited.person().id().value(), Map.of("invited", true)));
        return new AddedAdmin(invited, true);
    }

    /** A promoted member without a login gets one (the invitation saga; the setup e-mail is the last step). */
    private void giveLogin(Person member) {
        PersonalData data = member.data();
        ProvisionedIdentity login = logins.provision(
                new NewIdentity(data.email(), data.givenName(), data.familyName(), data.locale()));
        logins.compensateOnFailure(login, () -> {
            Person linked = provisioning.attachLogin(member, login);
            persons.update(linked);
            provisioning.indexMembership(login, linked);
            provisioning.sendSetupEmail(Optional.of(login));
            return linked;
        });
    }

    private Person requireActiveAdmin(PersonId id) {
        return persons.find(id).filter(person -> person.active() && person.isAdmin())
                .orElseThrow(() -> new NotFoundException("Administrator not found"));
    }
}
