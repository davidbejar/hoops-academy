package com.hoopsacademy.common.tenancy;

import java.time.ZoneId;
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
 * @param playerTeamIds   teams with a current assignment of the own player or a linked player (core computes it)
 * @param timezone        the tenant's IANA zone, when the resolver knows it (core always does)
 * @param historicStaffTeamIds teams of ended seasons the caller is still recorded as staff of: read-only history
 *                        (ADR-0042); never part of {@code staffTeamIds}
 */
public record AuthzContext(
        String subject,
        UUID personId,
        TenantId tenantId,
        Set<TenantRole> roles,
        Set<UUID> staffTeamIds,
        Set<UUID> linkedPlayerIds,
        Optional<UUID> ownPlayerId,
        Set<UUID> playerTeamIds,
        Optional<ZoneId> timezone,
        Set<UUID> historicStaffTeamIds) {

    public AuthzContext {
        Objects.requireNonNull(subject, "subject");
        Objects.requireNonNull(personId, "personId");
        Objects.requireNonNull(tenantId, "tenantId");
        roles = roles.isEmpty() ? Set.of() : Set.copyOf(EnumSet.copyOf(roles));
        staffTeamIds = Set.copyOf(staffTeamIds);
        linkedPlayerIds = Set.copyOf(linkedPlayerIds);
        ownPlayerId = Objects.requireNonNullElse(ownPlayerId, Optional.empty());
        playerTeamIds = playerTeamIds == null ? Set.of() : Set.copyOf(playerTeamIds);
        timezone = Objects.requireNonNullElse(timezone, Optional.empty());
        historicStaffTeamIds = historicStaffTeamIds == null ? Set.of() : Set.copyOf(historicStaffTeamIds);
    }

    /** Context without historic staff teams (resolvers and tests that do not know them). */
    public AuthzContext(String subject, UUID personId, TenantId tenantId, Set<TenantRole> roles, Set<UUID> staffTeamIds,
            Set<UUID> linkedPlayerIds, Optional<UUID> ownPlayerId, Set<UUID> playerTeamIds, Optional<ZoneId> timezone) {
        this(subject, personId, tenantId, roles, staffTeamIds, linkedPlayerIds, ownPlayerId, playerTeamIds, timezone,
                Set.of());
    }

    /** Context without player teams and zone (tests, and resolvers that cannot know them). */
    public AuthzContext(String subject, UUID personId, TenantId tenantId, Set<TenantRole> roles, Set<UUID> staffTeamIds,
            Set<UUID> linkedPlayerIds, Optional<UUID> ownPlayerId) {
        this(subject, personId, tenantId, roles, staffTeamIds, linkedPlayerIds, ownPlayerId, Set.of(), Optional.empty());
    }

    /** The same context with {@code teamIds} as its historic staff teams. */
    public AuthzContext withHistoricStaffTeamIds(Set<UUID> teamIds) {
        return new AuthzContext(subject, personId, tenantId, roles, staffTeamIds, linkedPlayerIds, ownPlayerId,
                playerTeamIds, timezone, teamIds);
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

    /**
     * COACH or ASSISTANT_COACH still recorded as staff of {@code teamId}, a team whose season has ended: may read its
     * history, never write it (ADR-0042).
     */
    public boolean wasStaffOf(UUID teamId) {
        return roles.stream().anyMatch(TenantRole::isTeamStaffRole) && historicStaffTeamIds.contains(teamId);
    }

    /** PARENT with a guardian_link to {@code playerId}. */
    public boolean isGuardianOf(UUID playerId) {
        return hasRole(TenantRole.PARENT) && linkedPlayerIds.contains(playerId);
    }

    /** {@code teamId} is a current team of the caller's own player or of a player they are guardian of. */
    public boolean isPlayerTeam(UUID teamId) {
        return playerTeamIds.contains(teamId);
    }

    /** PLAYER whose own player record is {@code playerId}. */
    public boolean isSelf(UUID playerId) {
        return hasRole(TenantRole.PLAYER) && ownPlayerId.filter(playerId::equals).isPresent();
    }
}
