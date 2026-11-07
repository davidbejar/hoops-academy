package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.PlayerBrief;
import com.hoopsacademy.game.application.RosterPort;
import com.hoopsacademy.game.application.TeamRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Typed;
import jakarta.transaction.Transactional;
import java.util.Collection;
import java.util.List;

/**
 * {@link RosterPort} over the local replica (ADR-0037, {@code hoops.roster.source=replica}), with core's
 * {@code /internal} rules: only an ACTIVE tenant has rosters and players, a roster lists the open valid assignments
 * of players with birth date and gender. Joins the caller's transaction, whose bound tenant must be
 * {@code tenantId} (otherwise the tenant is not visible and everything is not found).
 */
@ApplicationScoped
@Typed(ReplicaRosterPort.class)
public class ReplicaRosterPort implements RosterPort {

    private final RosterReplicaQueries replica;

    public ReplicaRosterPort(RosterReplicaQueries replica) {
        this.replica = replica;
    }

    @Override
    @Transactional
    public TeamRoster teamRoster(TenantId tenantId, TeamId teamId) {
        requireActiveTenant(tenantId);
        ReplicaTeam team = replica.team(teamId).orElseThrow(() -> new NotFoundException("Team not found"));
        List<TeamRoster.Player> players = replica.roster(teamId).stream()
                .filter(line -> line.player().hasBirthDateAndGender())
                .map(line -> new TeamRoster.Player(line.player().id(), line.player().displayName(),
                        line.jerseyNumber().orElse(null)))
                .toList();
        return new TeamRoster(team.id(), team.seasonId(), team.name(), players, team.seasonEndDate());
    }

    @Override
    @Transactional
    public List<PlayerBrief> players(TenantId tenantId, Collection<PlayerId> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        requireActiveTenant(tenantId);
        return replica.players(ids.stream().distinct().toList()).stream()
                .filter(ReplicaPlayer::hasBirthDateAndGender)
                .map(player -> new PlayerBrief(player.id(), player.displayName()))
                .toList();
    }

    private void requireActiveTenant(TenantId tenantId) {
        replica.tenant(tenantId).filter(ReplicaTenant::active)
                .orElseThrow(() -> new NotFoundException("Tenant not found"));
    }
}
