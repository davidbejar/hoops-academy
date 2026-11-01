package com.hoopsacademy.game.application;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.projection.SeasonStats;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;

/**
 * A player's season statistics over LIVE and FINISHED matches (contract getPlayerSeasonStats). Visible to ADMIN and
 * COACH / ASSISTANT_COACH, a linked PARENT and the PLAYER themself; anybody else gets 404 (matrix "view match stats").
 */
@ApplicationScoped
public class GetPlayerSeasonStats {

    private final ProjectionRepository projections;
    private final CurrentCaller caller;

    GetPlayerSeasonStats(ProjectionRepository projections, CurrentCaller caller) {
        this.projections = projections;
        this.caller = caller;
    }

    @Transactional
    public SeasonStats handle(PlayerId playerId, SeasonId seasonId) {
        AuthzContext authz = caller.authz();
        boolean visible = authz.hasAnyRole(List.of(TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH))
                || authz.isGuardianOf(playerId.value()) || authz.isSelf(playerId.value());
        if (!visible) {
            throw new NotFoundException("Player " + playerId + " not found");
        }
        return SeasonStats.of(playerId, seasonId, projections.seasonLines(playerId, seasonId));
    }
}
