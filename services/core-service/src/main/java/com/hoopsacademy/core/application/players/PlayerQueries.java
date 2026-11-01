package com.hoopsacademy.core.application.players;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerFilter;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerRow;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;

/** Player reads with the visibility rules of the authz matrix; invisible players do not exist (404). */
@ApplicationScoped
public class PlayerQueries {

    /** Contract query of {@code listPlayers}. */
    public record Query(Optional<PlayerStatus> status, Optional<TeamId> team, Optional<String> text) {}

    private final PlayerRepository players;
    private final PlayerViews views;
    private final PlayerAccess access;

    public PlayerQueries(PlayerRepository players, PlayerViews views, PlayerAccess access) {
        this.players = players;
        this.views = views;
        this.access = access;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT,
            TenantRole.PLAYER})
    public PageResult<PlayerView> list(Query query, PageRequest page) {
        PageResult<PlayerRow> found = players.page(
                new PlayerFilter(query.status(), query.team(), query.text(), access.visibility()), page);
        return new PageResult<>(views.of(found.items()), page, found.totalElements());
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT,
            TenantRole.PLAYER})
    public PlayerView get(PlayerId id) {
        return views.of(visible(id));
    }

    /** The row, or 404 when it does not exist or the caller may not see it. */
    public PlayerRow visible(PlayerId id) {
        return players.find(id).filter(access::canSee).orElseThrow(() -> new NotFoundException("Player not found"));
    }
}
