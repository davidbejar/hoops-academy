package com.hoopsacademy.common.tenancy;

import java.util.Collection;
import java.util.EnumSet;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * What the authenticated caller may do inside one tenant: their roles plus the relations the
 * authorization matrix ({@code docs/domain/authz-matrix.md}) refers to.
 *
 * @param subject         the OIDC subject ({@code sub}) of the caller
 * @param personId        the caller's person in this tenant
 * @param tenantId        the tenant this context is valid for
 * @param roles           tenant roles, possibly empty for a plain member
 * @param staffTeamIds    teams the caller is staff of (team_staff rows)
 * @param linkedPlayerIds players the caller is guardian of (guardian_link rows)
 * @param ownPlayerId     the caller's own player record, if they are a player
 */
public record AuthzContext(
        String subject,
        UUID personId,
        TenantId tenantId,
        Set<TenantRole> roles,
        Set<UUID> staffTeamIds,
        Set<UUID> linkedPlayerIds,
        Optional<UUID> ownPlayerId) {

    public AuthzContext {
        Objects.requireNonNull(subject, "subject");
        Objects.requireNonNull(personId, "personId");
        Objects.requireNonNull(tenantId, "tenantId");
        roles = roles.isEmpty() ? Set.of() : Set.copyOf(EnumSet.copyOf(roles));
        staffTeamIds = Set.copyOf(staffTeamIds);
        linkedPlayerIds = Set.copyOf(linkedPlayerIds);
        ownPlayerId = Objects.requireNonNullElse(ownPlayerId, Optional.empty());
    }

    public boolean hasRole(TenantRole role) {
        return roles.contains(role);
    }

    /** Any-of semantics: true when the caller holds at least one of {@code anyOf}. */
    public boolean hasAnyRole(Collection<TenantRole> anyOf) {
        return anyOf.stream().anyMatch(roles::contains);
    }

    /** COACH or ASSISTANT_COACH with a team_staff row for {@code teamId}. */
    public boolean isStaffOf(UUID teamId) {
        return roles.stream().anyMatch(TenantRole::isTeamStaffRole) && staffTeamIds.contains(teamId);
    }

    /** PARENT with a guardian_link to {@code playerId}. */
    public boolean isGuardianOf(UUID playerId) {
        return hasRole(TenantRole.PARENT) && linkedPlayerIds.contains(playerId);
    }

    /** PLAYER whose own player record is {@code playerId}. */
    public boolean isSelf(UUID playerId) {
        return hasRole(TenantRole.PLAYER) && ownPlayerId.filter(playerId::equals).isPresent();
    }
}
