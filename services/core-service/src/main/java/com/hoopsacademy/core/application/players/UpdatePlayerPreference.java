package com.hoopsacademy.core.application.players;

import com.hoopsacademy.common.authz.Authz;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerRow;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.shared.Patch;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Objects;

/**
 * PATCH /api/core/players/{id}: the preferred jersey number (decision 70, ADR-0048). ADMIN and COACH set it for any
 * player they read; a PARENT for a linked player and a PLAYER for themselves set it as a wish; an ASSISTANT_COACH
 * may not (403). A player the caller cannot read does not exist (404, as {@code getPlayer}). An unchanged value writes
 * nothing; the preference is neither audited nor published (the {@code core.player} event does not carry it).
 */
@ApplicationScoped
public class UpdatePlayerPreference {

    private final PlayerQueries queries;
    private final PlayerRepository players;
    private final PlayerViews views;
    private final PlayerAccess access;
    private final Authz authz;

    public UpdatePlayerPreference(PlayerQueries queries, PlayerRepository players, PlayerViews views,
            PlayerAccess access, Authz authz) {
        this.queries = queries;
        this.players = players;
        this.views = views;
        this.access = access;
        this.authz = authz;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT,
            TenantRole.PLAYER})
    public PlayerView preferJersey(PlayerId id, Patch<JerseyNumber> preferred) {
        PlayerRow row = queries.visible(id);
        authz.require(authz.hasAnyRole(TenantRole.ADMIN, TenantRole.COACH) || access.isLinkedOrSelf(id),
                "Only ADMIN, a COACH, the player's guardian or the player may set the preferred jersey number");
        JerseyNumber current = row.summary().preferredJersey();
        JerseyNumber next = preferred.applyTo(current);
        if (Objects.equals(current, next)) {
            return views.of(row);
        }
        players.updatePreferredJersey(id, next);
        return views.of(players.find(id).orElseThrow());
    }
}
