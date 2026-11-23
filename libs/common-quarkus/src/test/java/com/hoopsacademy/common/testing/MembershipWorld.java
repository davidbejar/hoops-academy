package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * What one tenant's membership tables hold for one login, as the rule that builds an authorisation context sees them
 * (ADR-0066): the tenant's status, the login's active person and roles, the person's own player, guardian links and
 * staff rows, the open valid assignments of players and the season end of each team the store knows. Each service maps
 * it onto its own reads (core's repositories, a replica's queries) in {@link MembershipRuleContract}.
 */
public final class MembershipWorld {

    public static final TenantId TENANT = new TenantId(UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c001"));
    public static final ZoneId ZONE = ZoneId.of("Asia/Jakarta");
    /** 20:00 UTC on 6 November is already 7 November in Jakarta (UTC+7). */
    public static final Clock CLOCK = Clock.fixed(Instant.parse("2026-11-06T20:00:00Z"), ZoneOffset.UTC);
    public static final LocalDate TODAY_IN_ZONE = LocalDate.parse("2026-11-07");
    public static final String SUBJECT = "sub-member";
    public static final UUID PERSON = UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c002");

    /** Season ends today in the academy's zone: current. */
    public static final UUID CURRENT_TEAM = UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c101");
    /** Season ends next summer: current. */
    public static final UUID NEXT_SUMMER_TEAM = UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c102");
    /** Season ended yesterday in the academy's zone, although that is still today in UTC: ended. */
    public static final UUID ENDED_TEAM = UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c103");
    /** A team the store does not know (no season end). */
    public static final UUID UNKNOWN_TEAM = UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c104");

    public static final UUID OWN_PLAYER = UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c201");
    public static final UUID CHILD = UUID.fromString("0b9e4a3c-6f21-4c3e-9f61-2b7d10a4c202");

    private static final Map<UUID, LocalDate> KNOWN_TEAMS = Map.of(
            CURRENT_TEAM, TODAY_IN_ZONE,
            NEXT_SUMMER_TEAM, LocalDate.parse("2027-06-30"),
            ENDED_TEAM, LocalDate.parse("2026-11-06"));

    private Optional<TenantStatus> tenantStatus = Optional.of(TenantStatus.ACTIVE);
    private Optional<Set<TenantRole>> memberRoles = Optional.empty();
    private Optional<UUID> ownPlayer = Optional.empty();
    private final Set<UUID> guardedPlayers = new HashSet<>();
    private final Set<UUID> staffTeams = new HashSet<>();
    private final Map<UUID, Set<UUID>> openValidTeams = new HashMap<>();

    private MembershipWorld() {}

    /** An ACTIVE tenant in which the login has an active person with {@code roles} and no relations yet. */
    public static MembershipWorld member(TenantRole first, TenantRole... more) {
        MembershipWorld world = new MembershipWorld();
        world.memberRoles = Optional.of(Set.copyOf(EnumSet.of(first, more)));
        return world;
    }

    /** An ACTIVE tenant in which the login has no active person. */
    public static MembershipWorld noMember() {
        return new MembershipWorld();
    }

    public MembershipWorld tenant(TenantStatus status) {
        tenantStatus = Optional.of(status);
        return this;
    }

    public MembershipWorld unknownTenant() {
        tenantStatus = Optional.empty();
        return this;
    }

    public MembershipWorld ownPlayer(UUID player, UUID... teams) {
        ownPlayer = Optional.of(player);
        return assigned(player, teams);
    }

    public MembershipWorld guardianOf(UUID player, UUID... teams) {
        guardedPlayers.add(player);
        return assigned(player, teams);
    }

    public MembershipWorld staffOf(UUID... teams) {
        staffTeams.addAll(Set.of(teams));
        return this;
    }

    private MembershipWorld assigned(UUID player, UUID... teams) {
        openValidTeams.computeIfAbsent(player, p -> new HashSet<>()).addAll(Set.of(teams));
        return this;
    }

    /** The tenant's lifecycle status; empty when the store does not know the tenant. */
    public Optional<TenantStatus> tenantStatus() {
        return tenantStatus;
    }

    /** The roles of the login's active person ({@link #PERSON}); empty when there is none. */
    public Optional<Set<TenantRole>> memberRoles() {
        return memberRoles;
    }

    /** The person's own player record, whatever the roles. */
    public Optional<UUID> ownPlayer() {
        return ownPlayer;
    }

    /** The players the person has a guardian link to, whatever the roles. */
    public Set<UUID> guardedPlayers() {
        return Set.copyOf(guardedPlayers);
    }

    /** The teams the person has a staff row for, whatever the roles. */
    public Set<UUID> staffTeams() {
        return Set.copyOf(staffTeams);
    }

    /** The teams with an open, valid assignment of {@code player}. */
    public Set<UUID> openValidTeamsOf(UUID player) {
        return Set.copyOf(openValidTeams.getOrDefault(player, Set.of()));
    }

    /** The season end of a team the store knows; empty for {@link #UNKNOWN_TEAM} and any other id. */
    public Optional<LocalDate> seasonEnd(UUID team) {
        return Optional.ofNullable(KNOWN_TEAMS.get(team));
    }

    /** Every team the store knows (core's foreign keys make every referenced team one of them). */
    public Set<UUID> knownTeams() {
        return KNOWN_TEAMS.keySet();
    }
}
