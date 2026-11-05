package com.hoopsacademy.game.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.PlayerVisibility;
import com.hoopsacademy.game.domain.TeamId;
import java.util.stream.Stream;

/**
 * The one place that decides whose statistics a caller sees in a match of {@code team} (docs/domain/authz-matrix.md
 * "View match stats", ADR-0021 §3, ADR-0028): ADMIN and staff of the team see every player; anybody else sees the
 * players they are guardian of (PARENT) and their own player (PLAYER). Box-score lines and the event feed use it.
 */
final class StatVisibility {

    private StatVisibility() {}

    static PlayerVisibility forTeam(AuthzContext caller, TeamId team) {
        if (caller.hasRole(TenantRole.ADMIN) || caller.isStaffOf(team.value())) {
            return PlayerVisibility.everyone();
        }
        Stream<PlayerId> linked = caller.linkedPlayerIds().stream().filter(caller::isGuardianOf).map(PlayerId::of);
        Stream<PlayerId> own = caller.ownPlayerId().filter(caller::isSelf).map(PlayerId::of).stream();
        return PlayerVisibility.only(Stream.concat(linked, own).toList());
    }
}
