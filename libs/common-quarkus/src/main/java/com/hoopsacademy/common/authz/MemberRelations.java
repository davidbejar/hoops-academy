package com.hoopsacademy.common.authz;

import java.time.LocalDate;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * The relations of a member that an authorisation context is built from (ADR-0066), read in the bound tenant (RLS).
 * Each service implements it over its own tables: core over its membership and roster tables, game and athlete over
 * their roster replicas (removed rows count as absent, ADR-0037). The ids are the plain values the context carries.
 */
public interface MemberRelations {

    /** The person's own player record, whatever their roles. */
    Optional<UUID> ownPlayer(UUID personId);

    /** The players the person has a guardian link to, whatever their roles. */
    Set<UUID> guardedPlayers(UUID personId);

    /** The teams the person has a staff row for, whatever their roles and whatever the season. */
    Set<UUID> staffTeams(UUID personId);

    /** The teams with an open, valid assignment of one of {@code players} (never called with an empty set). */
    Set<UUID> openValidTeamsOf(Set<UUID> players);

    /**
     * The last day of the season of each team among {@code teams} the store knows; a team it does not know is absent
     * (never called with an empty set).
     */
    Map<UUID, LocalDate> seasonEnds(Set<UUID> teams);
}
