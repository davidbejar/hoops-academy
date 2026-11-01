package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import java.util.ArrayList;
import java.util.List;

/** Mutable accumulator for one roster player during a replay. */
final class PlayerTally {

    private final PlayerId playerId;
    private final boolean starter;
    private final List<ProjectionWarning> warnings = new ArrayList<>();
    private boolean onCourt;
    private int enteredAtClock;
    private int seconds;
    private int fg1Made, fg1Attempted, fg2Made, fg2Attempted, fg3Made, fg3Attempted;
    private int assists, offensiveRebounds, defensiveRebounds, turnovers, steals, blocks;
    private int fouls, technicalFouls, unsportsmanlikeFouls;

    PlayerTally(PlayerId playerId, boolean starter) {
        this.playerId = playerId;
        this.starter = starter;
        this.onCourt = starter;
    }

    boolean onCourt() {
        return onCourt;
    }

    /** Enters the court; the clock only matters while a period is running. */
    void enter(int clock) {
        onCourt = true;
        enteredAtClock = clock;
    }

    /** Starts counting from {@code clock} (period start). */
    void resumeAt(int clock) {
        enteredAtClock = clock;
    }

    /** Adds the time since entering (or since the period started) up to {@code clock}. */
    void accrueUntil(int clock) {
        seconds += Math.max(0, enteredAtClock - clock);
        enteredAtClock = clock;
    }

    void leave() {
        onCourt = false;
    }

    void warn(ProjectionWarning warning) {
        warnings.add(warning);
    }

    void record(MatchEvent.PlayerStat stat) {
        switch (stat) {
            case MatchEvent.Shot s -> shot(s);
            case MatchEvent.Assist a -> assists++;
            case MatchEvent.Rebound r -> {
                if (r.kind() == MatchEvent.ReboundKind.OFFENSIVE) {
                    offensiveRebounds++;
                } else {
                    defensiveRebounds++;
                }
            }
            case MatchEvent.Turnover t -> turnovers++;
            case MatchEvent.Steal s -> steals++;
            case MatchEvent.Block b -> blocks++;
            case MatchEvent.Foul f -> foul(f.kind());
        }
    }

    private void shot(MatchEvent.Shot shot) {
        int made = shot.made() ? 1 : 0;
        switch (shot.points()) {
            case 1 -> { fg1Attempted++; fg1Made += made; }
            case 2 -> { fg2Attempted++; fg2Made += made; }
            default -> { fg3Attempted++; fg3Made += made; }
        }
    }

    private void foul(MatchEvent.FoulKind kind) {
        fouls++;
        if (kind == MatchEvent.FoulKind.TECHNICAL) {
            technicalFouls++;
        } else if (kind == MatchEvent.FoulKind.UNSPORTSMANLIKE) {
            unsportsmanlikeFouls++;
        }
    }

    PlayerLine toLine() {
        StatLine stats = new StatLine(fg1Made + 2 * fg2Made + 3 * fg3Made,
                fg1Made, fg1Attempted, fg2Made, fg2Attempted, fg3Made, fg3Attempted,
                assists, offensiveRebounds, defensiveRebounds, turnovers, steals, blocks,
                fouls, technicalFouls, unsportsmanlikeFouls, seconds);
        return new PlayerLine(playerId, starter, stats, warnings);
    }
}
