package com.hoopsacademy.core.domain.membership;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.domain.identity.UserId;
import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/**
 * A member of one tenant: personal data, additive tenant roles and an optional platform login. Immutable.
 * Invariants: at least one role; the PLAYER role requires birth date and gender.
 */
public record Person(
        PersonId id,
        UserId userId,
        PersonalData data,
        Set<TenantRole> roles,
        boolean active,
        InvitationStatus invitationStatus,
        Instant createdAt,
        Instant deactivatedAt) {

    public static final String PLAYER_REQUIRES_BIRTH_AND_GENDER = "PLAYER_REQUIRES_BIRTH_AND_GENDER";

    public Person {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(data, "data");
        roles = validRoles(roles, data);
    }

    public static Person create(PersonId id, PersonalData data, Set<TenantRole> roles, Instant now) {
        return new Person(id, null, data, roles, true, InvitationStatus.NONE, now, null);
    }

    public boolean isPlayer() {
        return roles.contains(TenantRole.PLAYER);
    }

    public boolean isAdmin() {
        return roles.contains(TenantRole.ADMIN);
    }

    public String displayName() {
        return data.displayName();
    }

    public Person withRoles(Set<TenantRole> newRoles) {
        return new Person(id, userId, data, newRoles, active, invitationStatus, createdAt, deactivatedAt);
    }

    public Person withData(PersonalDataChanges changes) {
        return new Person(id, userId, data.apply(changes), roles, active, invitationStatus, createdAt, deactivatedAt);
    }

    public Person linkLogin(UserId user, InvitationStatus status) {
        return new Person(id, user, data, roles, active, status, createdAt, deactivatedAt);
    }

    public Person acceptInvitation() {
        return new Person(id, userId, data, roles, active, InvitationStatus.ACCEPTED, createdAt, deactivatedAt);
    }

    public Person deactivate(Instant now) {
        return new Person(id, userId, data, roles, false, invitationStatus, createdAt, now);
    }

    private static Set<TenantRole> validRoles(Set<TenantRole> roles, PersonalData data) {
        if (roles == null || roles.isEmpty()) {
            throw new DomainRuleViolation("A member needs at least one role", "ROLES_REQUIRED");
        }
        Set<TenantRole> copy = Set.copyOf(EnumSet.copyOf(roles));
        if (copy.contains(TenantRole.PLAYER)) {
            requirePlayerData(data);
        }
        return copy;
    }

    private static void requirePlayerData(PersonalData data) {
        List<Problem.Violation> missing = new ArrayList<>();
        if (data.birthDate() == null) {
            missing.add(new Problem.Violation("birthDate", "MISSING_BIRTH_DATE", "A player needs a birth date"));
        }
        if (data.gender() == null) {
            missing.add(new Problem.Violation("gender", "MISSING_GENDER", "A player needs a gender"));
        }
        if (!missing.isEmpty()) {
            throw new DomainRuleViolation("The PLAYER role requires birth date and gender",
                    PLAYER_REQUIRES_BIRTH_AND_GENDER, missing);
        }
    }
}
