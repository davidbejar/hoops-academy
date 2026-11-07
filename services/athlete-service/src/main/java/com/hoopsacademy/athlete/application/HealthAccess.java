package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.SeasonEndedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * The health part of the authorization matrix ({@code docs/domain/authz-matrix.md}): injuries, height / weight and test
 * results of a player. Unlike training data, health data is confined to the players of the caller's own teams:
 * <ul>
 *   <li>manage (write everything): ADMIN, or a staff role with a team the player is in</li>
 *   <li>family write (injuries, measurements): manage, or the PARENT linked to the player</li>
 *   <li>read: family write, or the PLAYER himself</li>
 *   <li>history (ADR-0042): a staff role still recorded as staff of a team whose season has ended reads the records of
 *       that team's players dated on or before the season's last day, and never writes them (409
 *       {@code SEASON_ENDED})</li>
 * </ul>
 * A caller who may not read the player gets 404 for a single resource; 403 when naming such a player in a filter or
 * in a request body; 403 when able to read but not to write.
 */
@ApplicationScoped
public class HealthAccess {

    /** The players a list may contain ({@code null} = every player) and the last day its records may be dated on. */
    public record Scope(Set<PlayerId> players, Optional<LocalDate> until) {

        /** The end of a requested date range, capped by {@link #until}. */
        public LocalDate cap(LocalDate to) {
            return until.filter(day -> day.isBefore(to)).orElse(to);
        }
    }

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

    /**
     * The last day of the latest ended season in which the caller was staff of a team the player is on: they read the
     * player's records dated up to it (ADR-0042). Empty without such a team.
     */
    public Optional<LocalDate> historyUntil(AuthzContext caller, PlayerId player) {
        return caller.historicStaffTeamIds().stream().filter(caller::wasStaffOf)
                .map(team -> plans.teamRoster(caller.tenantId(), new TeamId(team)))
                .flatMap(Optional::stream)
                .filter(teamRoster -> teamRoster.hasPlayer(player))
                .map(TeamRoster::seasonEnd).flatMap(Optional::stream)
                .max(Comparator.naturalOrder());
    }

    public void requireManage(AuthzContext caller, PlayerId player) {
        if (!mayManage(caller, player)) {
            refuse(caller, player, "Only an administrator or staff of the player's team may do this");
        }
    }

    public void requireWriteAsFamily(AuthzContext caller, PlayerId player) {
        if (!mayWriteAsFamily(caller, player)) {
            refuse(caller, player, "Only an administrator, staff of the player's team or the player's guardian may do this");
        }
    }

    /** Today's view of the player (e.g. availability), without history. @throws NotFoundException when not readable */
    public void requireRead(AuthzContext caller, PlayerId player, String what) {
        if (!mayRead(caller, player)) {
            throw new NotFoundException(what + " not found");
        }
    }

    /** A record dated {@code on}: readable today, or as history up to the season's last day; 404 otherwise. */
    public void requireRead(AuthzContext caller, PlayerId player, LocalDate on, String what) {
        if (!mayRead(caller, player) && historyUntil(caller, player).filter(until -> !on.isAfter(until)).isEmpty()) {
            throw new NotFoundException(what + " not found");
        }
    }

    /**
     * The players a list may contain ({@code null} = every player: ADMIN without filters), otherwise the players the
     * caller can read, narrowed by an optional player and team filter; naming a player the caller may not read is 403.
     * History (ADR-0042): a {@code team} of an ended season the caller was staff of lists its roster's records dated up
     * to the season's last day, and a {@code player} read only as history caps them the same way.
     */
    public Scope listScope(AuthzContext caller, Optional<PlayerId> player, Optional<TeamId> team) {
        Optional<LocalDate> until = Optional.empty();
        if (player.isPresent() && !mayRead(caller, player.get())) {
            until = historyUntil(caller, player.get());
            if (until.isEmpty()) {
                throw new AccessDeniedException("Not allowed to see the data of this player");
            }
        }
        Optional<TeamRoster> teamRoster = team.map(t -> roster.teamRoster(caller.tenantId(), t));
        Optional<LocalDate> teamHistory = team.filter(t -> !caller.hasRole(TenantRole.ADMIN) && caller.wasStaffOf(t.value()))
                .flatMap(t -> teamRoster.flatMap(TeamRoster::seasonEnd));
        Set<PlayerId> scope = caller.hasRole(TenantRole.ADMIN) || teamHistory.isPresent() || until.isPresent()
                ? null : readablePlayers(caller);
        if (teamRoster.isPresent()) {
            scope = intersect(scope, teamRoster.get().playerIds());
            until = earliest(until, teamHistory);
        }
        if (player.isPresent()) {
            scope = intersect(scope, List.of(player.get()));
        }
        return new Scope(scope, until);
    }

    /** A staff member whose only relation to the player is a past season gets 409, anybody else 403. */
    private void refuse(AuthzContext caller, PlayerId player, String reason) {
        if (historyUntil(caller, player).isPresent()) {
            throw new SeasonEndedException("The season of the player's team has ended; its records are read-only");
        }
        throw new AccessDeniedException(reason);
    }

    private Set<PlayerId> readablePlayers(AuthzContext caller) {
        Set<PlayerId> readable = new HashSet<>(training.relatedPlayers(caller));
        if (training.hasStaffRole(caller)) {
            for (UUID team : caller.staffTeamIds()) {
                plans.teamRoster(caller.tenantId(), new TeamId(team)).ifPresent(r -> readable.addAll(r.playerIds()));
            }
        }
        return readable;
    }

    private static Optional<LocalDate> earliest(Optional<LocalDate> one, Optional<LocalDate> other) {
        if (one.isEmpty()) {
            return other;
        }
        return other.filter(date -> date.isBefore(one.get())).or(() -> one);
    }

    private static Set<PlayerId> intersect(Set<PlayerId> scope, Collection<PlayerId> others) {
        Set<PlayerId> result = new HashSet<>(others);
        if (scope != null) {
            result.retainAll(scope);
        }
        return result;
    }
}
