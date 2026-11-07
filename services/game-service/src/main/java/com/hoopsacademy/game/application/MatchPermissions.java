package com.hoopsacademy.game.application;

import com.hoopsacademy.common.authz.Authz;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.UUID;

/**
 * Who may manage matches of a team: ADMIN or staff (COACH / ASSISTANT_COACH) of that very team
 * (docs/domain/authz-matrix.md). Anybody else who is a tenant member gets 403. Reading is open to all members. Once the
 * team's season has ended nobody manages its matches: ADMIN and the team's former staff get 409 {@code SEASON_ENDED}
 * (ADR-0042).
 */
@ApplicationScoped
public class MatchPermissions {

    private final Authz authz;
    private final PastSeasons pastSeasons;

    public MatchPermissions(Authz authz, PastSeasons pastSeasons) {
        this.authz = authz;
        this.pastSeasons = pastSeasons;
    }

    public void requireCanManage(TeamId teamId) {
        UUID team = teamId.value();
        authz.require(authz.isAdmin() || authz.isStaffOf(team) || authz.wasStaffOf(team),
                "Only an admin or staff of this team may do this");
        pastSeasons.requireOpen(teamId);
    }
}
