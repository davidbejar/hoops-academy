package com.hoopsacademy.common.authz;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Predicate;
import java.util.stream.Collectors;

/**
 * The rule that builds a caller's authorisation context from the membership tables, written once for core, game and
 * athlete (ADR-0066; the oracle is {@code docs/domain/authz-matrix.md}). Only an active person with the login in an
 * ACTIVE tenant is a member. The own player counts with the PLAYER role, guardian links with the PARENT role. Staff
 * teams and the teams of the own and linked players' open, valid assignments count while their season has not ended
 * (it ends today in the academy's zone or later); the staff teams whose season has ended are the historic staff teams
 * (read-only history, ADR-0042). A team the store does not know counts neither as current nor as historic. Every read
 * goes through the caller's ports, in the bound tenant: nothing here holds or shares tenant data.
 */
public final class MembershipRule {

    private MembershipRule() {}

    /** The context of {@code subject} in {@code tenant}; empty when they are not a member (the caller answers 404). */
    public static Optional<AuthzContext> resolve(String subject, TenantId tenant, MembershipReads reads, Clock clock) {
        return reads.tenant(tenant).filter(MembershipReads.TenantState::active)
                .flatMap(state -> reads.activeMember(subject)
                        .map(member -> contextOf(subject, tenant, state.timezone(), member, reads, clock)));
    }

    /**
     * The context of a member already found in {@code tenant}, whose lifecycle status the caller checks (core reports
     * it next to the context on {@code /internal/authz}).
     */
    public static AuthzContext contextOf(String subject, TenantId tenant, ZoneId zone, Member member,
            MemberRelations relations, Clock clock) {
        Optional<UUID> ownPlayer = member.has(TenantRole.PLAYER)
                ? relations.ownPlayer(member.personId())
                : Optional.empty();
        Set<UUID> linkedPlayers = member.has(TenantRole.PARENT)
                ? relations.guardedPlayers(member.personId())
                : Set.of();
        Set<UUID> staffTeams = relations.staffTeams(member.personId());
        Set<UUID> playerTeams = teamsOf(ownPlayer, linkedPlayers, relations);
        Map<UUID, LocalDate> seasonEnds = seasonEnds(staffTeams, playerTeams, relations);
        LocalDate today = LocalDate.ofInstant(clock.instant(), zone);
        Set<UUID> current = teamsWhere(seasonEnds, lastDay -> !lastDay.isBefore(today));
        Set<UUID> ended = teamsWhere(seasonEnds, lastDay -> lastDay.isBefore(today));
        return new AuthzContext(subject, member.personId(), tenant, member.roles(), among(staffTeams, current),
                linkedPlayers, ownPlayer, among(playerTeams, current), Optional.of(zone), among(staffTeams, ended));
    }

    private static Set<UUID> teamsOf(Optional<UUID> ownPlayer, Set<UUID> linkedPlayers, MemberRelations relations) {
        Set<UUID> players = new HashSet<>(linkedPlayers);
        ownPlayer.ifPresent(players::add);
        return players.isEmpty() ? Set.of() : relations.openValidTeamsOf(players);
    }

    /** One read for both team sets. */
    private static Map<UUID, LocalDate> seasonEnds(Set<UUID> staffTeams, Set<UUID> playerTeams,
            MemberRelations relations) {
        Set<UUID> candidates = new HashSet<>(staffTeams);
        candidates.addAll(playerTeams);
        return candidates.isEmpty() ? Map.of() : relations.seasonEnds(candidates);
    }

    private static Set<UUID> teamsWhere(Map<UUID, LocalDate> seasonEnds, Predicate<LocalDate> lastDay) {
        return seasonEnds.entrySet().stream().filter(team -> lastDay.test(team.getValue())).map(Map.Entry::getKey)
                .collect(Collectors.toSet());
    }

    private static Set<UUID> among(Set<UUID> teams, Set<UUID> selected) {
        return teams.stream().filter(selected::contains).collect(Collectors.toSet());
    }
}
