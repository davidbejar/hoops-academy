package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * A team's current players as core reports them, with the last day of its season ({@code null} when core did not say:
 * an older core; counts as not ended, ADR-0042).
 */
public record TeamRoster(TeamId teamId, SeasonId seasonId, String teamName, List<Player> players,
        LocalDate seasonEndDate) {

    public TeamRoster {
        players = List.copyOf(players);
    }

    public Optional<Player> find(PlayerId playerId) {
        return players.stream().filter(p -> p.playerId().equals(playerId)).findFirst();
    }

    /** @param jerseyNumber the player's jersey in this team, null when none */
    public record Player(PlayerId playerId, String displayName, String jerseyNumber) {}
}
