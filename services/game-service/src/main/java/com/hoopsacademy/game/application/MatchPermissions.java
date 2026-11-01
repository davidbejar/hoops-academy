package com.hoopsacademy.game.application;

import com.hoopsacademy.common.authz.Authz;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * Who may manage matches of a team: ADMIN or staff (COACH / ASSISTANT_COACH) of that very team
 * (docs/domain/authz-matrix.md). Anybody else who is a tenant member gets 403. Reading is open to all members.
 */
@ApplicationScoped
public class MatchPermissions {

    private final Authz authz;

    public MatchPermissions(Authz authz) {
        this.authz = authz;
    }

    public void requireCanManage(TeamId teamId) {
        authz.require(authz.isAdmin() || authz.isStaffOf(teamId.value()), "Only an admin or staff of this team may do this");
    }
}
