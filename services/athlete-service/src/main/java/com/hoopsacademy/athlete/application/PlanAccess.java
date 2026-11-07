package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlanAssignment;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * The plan part of the authorization matrix ({@code docs/domain/authz-matrix.md}): who writes plans, assigns them,
 * sees assignments and marks completions. Staff roles read every assignment of the tenant (as WP8 reads every team);
 * writes need ADMIN or a staff relation to the team (for a player assignment: to a team the player is in). A team
 * assignment of a team whose season has ended is read-only: 409 {@code SEASON_ENDED} (ADR-0042).
 */
@ApplicationScoped
public class PlanAccess {

    private final TrainingAccess training;
    private final RosterPort roster;
    private final PastSeasons pastSeasons;

    public PlanAccess(TrainingAccess training, RosterPort roster, PastSeasons pastSeasons) {
        this.training = training;
        this.roster = roster;
        this.pastSeasons = pastSeasons;
    }

    /** ADMIN, COACH or ASSISTANT_COACH write plans (the matrix does not tie plan writing to a team). */
    public void requireStaffRole(AuthzContext caller) {
        if (!training.hasStaffRole(caller)) {
            throw new AccessDeniedException("Only an administrator or staff may manage training plans");
        }
    }

    public boolean isStaff(AuthzContext caller) {
        return training.hasStaffRole(caller);
    }

    /** Players the caller acts for as parent or player. */
    public Set<PlayerId> relatedPlayers(AuthzContext caller) {
        return training.relatedPlayers(caller);
    }

    /** Assigning to a team needs ADMIN or staff of it; to a player ADMIN (player must exist) or staff of one of the player's teams. */
    public void requireMayAssign(AuthzContext caller, PlanAssignment assignment) {
        if (assignment.teamId().isPresent()) {
            TeamId team = assignment.teamId().get();
            training.requireManage(caller, team);
            roster.teamRoster(caller.tenantId(), team);
        } else if (caller.hasRole(TenantRole.ADMIN)) {
            if (!roster.playerExists(caller.tenantId(), assignment.playerId().orElseThrow())) {
                throw new NotFoundException("Player not found");
            }
        } else if (!isStaffOfPlayer(caller, assignment.playerId().orElseThrow())) {
            throw new AccessDeniedException("Only staff of the player's team may assign plans to this player");
        }
    }

    /** ADMIN, or staff of the assignment's team (player assignment: of a team the player is in). */
    public boolean mayManage(AuthzContext caller, PlanAssignment assignment) {
        if (caller.hasRole(TenantRole.ADMIN)) {
            return true;
        }
        return assignment.teamId().map(team -> caller.isStaffOf(team.value()))
                .orElseGet(() -> isStaffOfPlayer(caller, assignment.playerId().orElseThrow()));
    }

    /** Withdrawing: as {@link #mayManage}; a team assignment follows the team's write rule (403 / 409 season ended). */
    public void requireMayWithdraw(AuthzContext caller, PlanAssignment assignment) {
        if (assignment.teamId().isPresent()) {
            training.requireManage(caller, assignment.teamId().get());
        } else if (!mayManage(caller, assignment)) {
            throw new AccessDeniedException("Only an administrator or staff of the assignment's team may withdraw it");
        }
    }

    /**
     * Marking a completion: {@link #mayMark} (403 otherwise; the team's former staff get the 409 instead); a team
     * assignment of a team whose season has ended is refused with 409 {@code SEASON_ENDED}.
     */
    public void requireMayMark(AuthzContext caller, PlanAssignment assignment, PlayerId player) {
        boolean formerStaff = assignment.teamId().filter(team -> caller.wasStaffOf(team.value())).isPresent();
        if (!formerStaff && !mayMark(caller, assignment, player)) {
            throw new AccessDeniedException("Not allowed to mark this player's completion");
        }
        assignment.teamId().ifPresent(team -> pastSeasons.requireOpen(caller, team));
    }

    /** Staff roles see every assignment; a parent or player only those that target one of their players (else 404). */
    public void requireView(AuthzContext caller, PlanAssignment assignment) {
        if (training.hasStaffRole(caller)) {
            return;
        }
        Set<PlayerId> related = training.relatedPlayers(caller);
        boolean visible = assignment.playerId().map(related::contains)
                .orElseGet(() -> teamRoster(caller.tenantId(), assignment.teamId().orElseThrow())
                        .map(r -> related.stream().anyMatch(r::hasPlayer)).orElse(false));
        if (!visible) {
            throw new NotFoundException("Assignment not found");
        }
    }

    /** ADMIN, staff of the assignment, the player's guardian or the player. */
    public boolean mayMark(AuthzContext caller, PlanAssignment assignment, PlayerId player) {
        return caller.hasRole(TenantRole.ADMIN) || caller.isGuardianOf(player.value()) || caller.isSelf(player.value())
                || mayManage(caller, assignment);
    }

    /** The current roster of a team, or empty when core no longer knows the team. */
    public Optional<TeamRoster> teamRoster(TenantId tenant, TeamId team) {
        try {
            return Optional.of(roster.teamRoster(tenant, team));
        } catch (NotFoundException e) {
            return Optional.empty();
        }
    }

    /** The teams among {@code candidates} whose current roster contains the player (the read-time fan-out). */
    public List<TeamId> teamsOf(TenantId tenant, PlayerId player, Collection<TeamId> candidates) {
        return candidates.stream().filter(team -> teamRoster(tenant, team).map(r -> r.hasPlayer(player)).orElse(false)).toList();
    }

    boolean isStaffOfPlayer(AuthzContext caller, PlayerId player) {
        return caller.staffTeamIds().stream().filter(caller::isStaffOf)
                .anyMatch(team -> teamRoster(caller.tenantId(), new TeamId(team)).map(r -> r.hasPlayer(player)).orElse(false));
    }
}
