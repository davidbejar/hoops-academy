package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * The training part of the authorization matrix ({@code docs/domain/authz-matrix.md}), applied to a resolved
 * {@link AuthzContext}. Non-members never get here (the tenant filter answers 404); members lacking a role get 403;
 * a parent or player probing something unrelated to them gets 404.
 */
@ApplicationScoped
public class TrainingAccess {

    private final RosterPort roster;

    public TrainingAccess(RosterPort roster) {
        this.roster = roster;
    }

    /** ADMIN, COACH or ASSISTANT_COACH: the roles that see every team's training data. */
    public boolean hasStaffRole(AuthzContext caller) {
        return caller.hasRole(TenantRole.ADMIN) || caller.hasRole(TenantRole.COACH)
                || caller.hasRole(TenantRole.ASSISTANT_COACH);
    }

    public boolean canManage(AuthzContext caller, TeamId team) {
        return caller.hasRole(TenantRole.ADMIN) || caller.isStaffOf(team.value());
    }

    /** Write access to a team's schedules, sessions and attendance: ADMIN or staff of that team (403 otherwise). */
    public void requireManage(AuthzContext caller, TeamId team) {
        if (!canManage(caller, team)) {
            throw new AccessDeniedException("Only an administrator or staff of this team may do this");
        }
    }

    /**
     * Read access to a team's training data: staff roles see all teams, parents/players only a current team of their
     * players (404 otherwise): {@code playerTeamIds} from core, else the team's roster.
     */
    public void requireView(AuthzContext caller, TeamId team) {
        if (hasStaffRole(caller) || caller.isPlayerTeam(team.value())) {
            return;
        }
        TeamRoster teamRoster = roster.teamRoster(caller.tenantId(), team);
        if (relatedPlayers(caller).stream().noneMatch(teamRoster::hasPlayer)) {
            throw new NotFoundException("Team not found");
        }
    }

    /** Teams of the caller's own / linked players, as core reports them ({@code AuthzContext.playerTeamIds}). */
    public Set<TeamId> playerTeams(AuthzContext caller) {
        Set<TeamId> teams = new HashSet<>();
        caller.playerTeamIds().forEach(id -> teams.add(new TeamId(id)));
        return teams;
    }

    /** Linked players (PARENT) plus the caller's own player (PLAYER). */
    public Set<PlayerId> relatedPlayers(AuthzContext caller) {
        Set<PlayerId> related = new HashSet<>();
        if (caller.hasRole(TenantRole.PARENT)) {
            caller.linkedPlayerIds().forEach(id -> related.add(new PlayerId(id)));
        }
        if (caller.hasRole(TenantRole.PLAYER)) {
            caller.ownPlayerId().ifPresent(id -> related.add(new PlayerId(id)));
        }
        return related;
    }

    /** May the caller read or change planned absences of the player? staff any, parent linked, player self. */
    public boolean mayHandleAbsencesOf(AuthzContext caller, PlayerId player) {
        return hasStaffRole(caller) || relatedPlayers(caller).contains(player);
    }

    public void requireAbsenceAccess(AuthzContext caller, PlayerId player) {
        if (!mayHandleAbsencesOf(caller, player)) {
            throw new AccessDeniedException("Not allowed to handle absences of this player");
        }
    }

    public static Set<java.util.UUID> uuids(Set<PlayerId> ids) {
        return ids.stream().map(PlayerId::value).collect(Collectors.toSet());
    }
}
