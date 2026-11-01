package com.hoopsacademy.game.adapters.out.client;

import com.hoopsacademy.common.client.CoreInternalClient;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.PlayerBrief;
import com.hoopsacademy.game.application.RosterPort;
import com.hoopsacademy.game.application.TeamRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * {@link RosterPort} over common-quarkus' {@link CoreRosterClient} (core {@code /internal}, cached, 404 → not found,
 * anything else → 503 UPSTREAM_UNAVAILABLE); this adapter only maps to game's types.
 */
@ApplicationScoped
public class RestRosterPort implements RosterPort {

    private final CoreRosterClient core;

    RestRosterPort(CoreRosterClient core) {
        this.core = core;
    }

    @Override
    public TeamRoster teamRoster(TenantId tenantId, TeamId teamId) {
        CoreInternalClient.TeamRosterDto dto = core.teamRoster(tenantId, teamId.value());
        return new TeamRoster(TeamId.of(dto.teamId()), SeasonId.of(dto.seasonId()), dto.teamName(),
                dto.players().stream()
                        .map(p -> new TeamRoster.Player(PlayerId.of(p.playerId()), p.displayName(), p.jerseyNumber()))
                        .toList());
    }

    @Override
    public List<PlayerBrief> players(TenantId tenantId, Collection<PlayerId> ids) {
        List<UUID> asked = ids.stream().map(PlayerId::value).distinct().sorted().toList();
        var found = core.players(tenantId, asked);
        return asked.stream().filter(found::containsKey)
                .map(id -> new PlayerBrief(PlayerId.of(id), found.get(id).displayName()))
                .toList();
    }

    /** Drops every cached core answer (tests, or an operator hook if a membership change must apply at once). */
    public void clearCache() {
        core.clearCache();
    }
}
