package com.hoopsacademy.game.domain;

import java.util.Collection;
import java.util.Set;

/**
 * Whose player statistics a viewer may see in one match: every player's, or only some players' (ADR-0021 §3,
 * ADR-0030). Box-score lines and player-attributed events follow it alike.
 *
 * @param seesAll every player is visible ({@code players} is then irrelevant and empty)
 * @param players the visible players when not {@code seesAll}
 */
public record PlayerVisibility(boolean seesAll, Set<PlayerId> players) {

    private static final PlayerVisibility EVERYONE = new PlayerVisibility(true, Set.of());

    public PlayerVisibility {
        players = Set.copyOf(players);
    }

    public static PlayerVisibility everyone() {
        return EVERYONE;
    }

    public static PlayerVisibility only(Collection<PlayerId> players) {
        return new PlayerVisibility(false, Set.copyOf(players));
    }

    public boolean sees(PlayerId player) {
        return seesAll || players.contains(player);
    }
}
