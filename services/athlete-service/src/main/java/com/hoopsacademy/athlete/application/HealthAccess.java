package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

/**
 * The health part of the authorization matrix ({@code docs/domain/authz-matrix.md}): injuries, height / weight and test
 * results of a player. Unlike training data, health data is confined to the players of the caller's own teams:
 * <ul>
 *   <li>manage (write everything): ADMIN, or a staff role with a team the player is in</li>
 *   <li>family write (injuries, measurements): manage, or the PARENT linked to the player</li>
 *   <li>read: family write, or the PLAYER himself</li>
 * </ul>
 * A caller who may not read the player gets 404 for a single resource; 403 when naming such a player in a filter or
 * in a request body; 403 when able to read but not to write.
 */
@ApplicationScoped
public class HealthAccess {

    private final PlanAccess plans;
    private final TrainingAccess training;
    private final RosterPort roster;

    public HealthAccess(PlanAccess plans, TrainingAccess training, RosterPort roster) {
        this.plans = plans;
        this.training = training;
        this.roster = roster;
    }

    public boolean mayManage(AuthzContext caller, PlayerId player) {
        return caller.hasRole(TenantRole.ADMIN) || (training.hasStaffRole(caller) && plans.isStaffOfPlayer(caller, player));
    }

    public boolean mayWriteAsFamily(AuthzContext caller, PlayerId player) {
        return mayManage(caller, player) || (caller.hasRole(TenantRole.PARENT) && caller.isGuardianOf(player.value()));
    }

    public boolean mayRead(AuthzContext caller, PlayerId player) {
        return mayWriteAsFamily(caller, player) || training.relatedPlayers(caller).contains(player);
    }

    public void requireManage(AuthzContext caller, PlayerId player) {
        if (!mayManage(caller, player)) {
            throw new AccessDeniedException("Only an administrator or staff of the player's team may do this");
        }
    }

    public void requireWriteAsFamily(AuthzContext caller, PlayerId player) {
        if (!mayWriteAsFamily(caller, player)) {
            throw new AccessDeniedException("Only an administrator, staff of the player's team or the player's guardian may do this");
        }
    }

    /** @throws NotFoundException when the caller may not read the player's data (hides its existence) */
    public void requireRead(AuthzContext caller, PlayerId player, String what) {
        if (!mayRead(caller, player)) {
            throw new NotFoundException(what + " not found");
        }
    }

    /**
     * The players a list may contain: {@code null} = every player (ADMIN without filters), otherwise the players the
     * caller can read, narrowed by an optional player and team filter. Naming a player the caller may not read is 403.
     */
    public Set<PlayerId> listScope(AuthzContext caller, Optional<PlayerId> player, Optional<TeamId> team) {
        player.ifPresent(p -> {
            if (!mayRead(caller, p)) {
                throw new AccessDeniedException("Not allowed to see the data of this player");
            }
        });
        Set<PlayerId> scope = caller.hasRole(TenantRole.ADMIN) ? null : readablePlayers(caller);
        if (team.isPresent()) {
            scope = intersect(scope, roster.teamRoster(caller.tenantId(), team.get()).playerIds());
        }
        if (player.isPresent()) {
            scope = intersect(scope, java.util.List.of(player.get()));
        }
        return scope;
    }

    private Set<PlayerId> readablePlayers(AuthzContext caller) {
        Set<PlayerId> readable = new HashSet<>(training.relatedPlayers(caller));
        if (training.hasStaffRole(caller)) {
            for (java.util.UUID team : caller.staffTeamIds()) {
                plans.teamRoster(caller.tenantId(), new TeamId(team)).ifPresent(r -> readable.addAll(r.playerIds()));
            }
        }
        return readable;
    }

    private static Set<PlayerId> intersect(Set<PlayerId> scope, java.util.Collection<PlayerId> others) {
        Set<PlayerId> result = new HashSet<>(others);
        if (scope != null) {
            result.retainAll(scope);
        }
        return result;
    }
}
