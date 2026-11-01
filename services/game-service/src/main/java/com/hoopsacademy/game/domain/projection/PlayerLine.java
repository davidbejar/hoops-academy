package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.PlayerId;
import java.util.List;
import java.util.Objects;

/** One roster player's projected statistics and the warnings attributed to them. */
public record PlayerLine(PlayerId playerId, boolean wasStarter, StatLine stats, List<ProjectionWarning> warnings) {

    public PlayerLine {
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(stats, "stats");
        warnings = List.copyOf(warnings);
    }
}
