package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.roster.TeamPlayerView;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Contract {@code TeamPlayer}. */
public record TeamPlayerDto(RefDtos.PlayerRef player, UUID teamId, String jerseyNumber, LocalDate joinedOn,
        LocalDate leftOn, int playUpLevels, Instant invalidatedAt, EligibilityReason invalidReason,
        PlayerStatus playerStatus) {

    static TeamPlayerDto of(TeamPlayerView view) {
        TeamPlayer a = view.assignment();
        return new TeamPlayerDto(new RefDtos.PlayerRef(a.player().value(), view.playerName()), a.team().value(),
                a.jersey() == null ? null : a.jersey().value(), a.joinedOn(), a.leftOn(), a.playUpLevels(),
                a.invalidatedAt(), a.invalidReason(), view.playerStatus());
    }
}
