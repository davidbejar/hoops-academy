package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.authz.MemberRelations;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import java.time.LocalDate;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * The membership rule's reads (ADR-0066) over core's own tables in the bound tenant. {@code team_staff} is the single
 * source of truth for the staff teams ({@code /internal/authz}, {@code /me}, {@code Authz.isStaffOf}); every staff row
 * and assignment points to an existing team (foreign keys), so every team asked for has a season end.
 */
final class CoreMemberRelations implements MemberRelations {

    private final PlayerRepository players;
    private final GuardianLinkRepository guardianLinks;
    private final TeamStaffRepository staff;
    private final TeamPlayerRepository assignments;
    private final TeamRepository teams;

    CoreMemberRelations(PlayerRepository players, GuardianLinkRepository guardianLinks, TeamStaffRepository staff,
            TeamPlayerRepository assignments, TeamRepository teams) {
        this.players = players;
        this.guardianLinks = guardianLinks;
        this.staff = staff;
        this.assignments = assignments;
        this.teams = teams;
    }

    @Override
    public Optional<UUID> ownPlayer(UUID personId) {
        return players.findByPerson(new PersonId(personId)).map(PlayerId::value);
    }

    @Override
    public Set<UUID> guardedPlayers(UUID personId) {
        return guardianLinks.playersOf(new PersonId(personId)).stream().map(PlayerId::value)
                .collect(Collectors.toSet());
    }

    @Override
    public Set<UUID> staffTeams(UUID personId) {
        return staff.teamsOf(new PersonId(personId)).stream().map(TeamId::value).collect(Collectors.toSet());
    }

    /** The teams of the open assignments that are valid (what the roster endpoint lists). */
    @Override
    public Set<UUID> openValidTeamsOf(Set<UUID> playerIds) {
        return assignments.openOfPlayers(playerIds.stream().map(PlayerId::new).toList()).stream()
                .filter(TeamPlayer::isValid)
                .map(assignment -> assignment.team().value())
                .collect(Collectors.toSet());
    }

    @Override
    public Map<UUID, LocalDate> seasonEnds(Set<UUID> teamIds) {
        return teams.seasonEnds(teamIds.stream().map(TeamId::new).toList()).entrySet().stream()
                .collect(Collectors.toMap(team -> team.getKey().value(), Map.Entry::getValue));
    }
}
