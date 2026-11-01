package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * One replay of a match's events in game order. Starters are on court before the first period; the clock only runs
 * between PERIOD_START and PERIOD_END, and substitutions while it is stopped change the lineup without adding time.
 * Anything impossible becomes a warning and the replay carries on.
 */
final class ProjectionRun {

    private final MatchRules rules;
    private final Map<PlayerId, PlayerTally> tallies = new LinkedHashMap<>();
    private final List<ProjectionWarning> matchWarnings = new ArrayList<>();
    private final Scoreboard scoreboard = new Scoreboard();
    private final Set<Integer> playedPeriods = new HashSet<>();
    private int currentPeriod;
    private boolean running;
    private int lastClock;
    private int lastPeriodSeen;

    ProjectionRun(MatchRules rules, List<RosterEntry> roster) {
        this.rules = rules;
        roster.forEach(entry -> tallies.put(entry.playerId(), new PlayerTally(entry.playerId(), entry.starter())));
        this.lastPeriodSeen = rules.periodCount();
    }

    void apply(MatchEvent event) {
        int period = event.meta().period();
        int clock = clampedClock(event);
        lastPeriodSeen = Math.max(lastPeriodSeen, period);
        if (running && period != currentPeriod) {
            matchWarn(WarningCode.MISSING_PERIOD_END, event, null, "Period " + currentPeriod + " was never ended");
            closePeriod(0);
        }
        switch (event) {
            case MatchEvent.PeriodStart start -> startPeriod(start, clock);
            case MatchEvent.PeriodEnd end -> endPeriod(end, clock);
            case MatchEvent.SubIn in -> subIn(in, clock);
            case MatchEvent.SubOut out -> subOut(out, clock);
            case MatchEvent.PlayerStat stat -> playerStat(stat);
            case MatchEvent.OpponentScore score -> opponentScore(score);
            case MatchEvent.Timeout timeout -> { }
            case MatchEvent.Note note -> { }
            case MatchEvent.Void ignored -> { }
        }
        if (running) {
            lastClock = clock;
        }
    }

    Projection finish(long lastServerSeq, VoidResolution voids) {
        if (running) {
            onCourt().forEach(t -> t.accrueUntil(lastClock));
        }
        List<ProjectionWarning> warnings = new ArrayList<>(voids.warnings());
        warnings.addAll(matchWarnings);
        List<PlayerLine> lines = tallies.values().stream().map(PlayerTally::toLine).toList();
        return new Projection(lines, scoreboard.summary(lastPeriodSeen, lastServerSeq), warnings, voids.voidedBy());
    }

    private int clampedClock(MatchEvent event) {
        int length = rules.periodSeconds(event.meta().period());
        int clock = event.meta().clockSecondsRemaining();
        if (clock > length) {
            matchWarn(WarningCode.CLOCK_OUT_OF_RANGE, event, null,
                    "Clock " + clock + " s exceeds the period length of " + length + " s");
            return length;
        }
        return clock;
    }

    private void startPeriod(MatchEvent.PeriodStart start, int clock) {
        int period = start.meta().period();
        if (running) {
            matchWarn(WarningCode.PERIOD_ALREADY_RUNNING, start, null, "Period " + period + " is already running");
        } else if (playedPeriods.contains(period)) {
            matchWarn(WarningCode.PERIOD_ALREADY_PLAYED, start, null, "Period " + period + " was already played");
        } else {
            running = true;
            currentPeriod = period;
            playedPeriods.add(period);
            onCourt().forEach(t -> t.resumeAt(clock));
        }
    }

    private void endPeriod(MatchEvent.PeriodEnd end, int clock) {
        if (running) {
            closePeriod(clock);
        } else {
            matchWarn(WarningCode.PERIOD_NOT_RUNNING, end, null, "Period " + end.meta().period() + " is not running");
        }
    }

    private void closePeriod(int clock) {
        onCourt().forEach(t -> t.accrueUntil(clock));
        running = false;
    }

    private void subIn(MatchEvent.SubIn in, int clock) {
        PlayerTally tally = rosterPlayer(in, in.player());
        if (tally == null) {
            return;
        }
        if (tally.onCourt()) {
            tally.warn(ProjectionWarning.of(WarningCode.SUB_IN_PLAYER_ON_COURT, in.id(), in.player(),
                    "Player is already on court (missing SUB_OUT?)"));
            return;
        }
        tally.enter(clock);
        if (onCourt().size() > MatchRules.PLAYERS_ON_COURT) {
            matchWarn(WarningCode.TOO_MANY_PLAYERS_ON_COURT, in, null,
                    onCourt().size() + " players on court (missing SUB_OUT?)");
        }
    }

    private void subOut(MatchEvent.SubOut out, int clock) {
        PlayerTally tally = rosterPlayer(out, out.player());
        if (tally == null) {
            return;
        }
        if (!tally.onCourt()) {
            tally.warn(ProjectionWarning.of(WarningCode.SUB_OUT_PLAYER_NOT_ON_COURT, out.id(), out.player(),
                    "Player is not on court (missing SUB_IN?)"));
            return;
        }
        if (running) {
            tally.accrueUntil(clock);
        }
        tally.leave();
    }

    private void playerStat(MatchEvent.PlayerStat stat) {
        if (stat instanceof MatchEvent.Shot shot && shot.made()) {
            scoreboard.team(shot.meta().period(), shot.points());
        }
        PlayerTally tally = rosterPlayer(stat, stat.player());
        if (tally == null) {
            return;
        }
        if (!running) {
            tally.warn(ProjectionWarning.of(WarningCode.EVENT_OUTSIDE_PERIOD, stat.id(), stat.player(),
                    "Recorded while no period was running"));
        } else if (!tally.onCourt() && !allowedFromTheBench(stat)) {
            tally.warn(ProjectionWarning.of(WarningCode.PLAYER_NOT_ON_COURT, stat.id(), stat.player(),
                    "Player was not on court"));
        }
        tally.record(stat);
    }

    private static boolean allowedFromTheBench(MatchEvent.PlayerStat stat) {
        return stat instanceof MatchEvent.Foul foul && foul.kind() != MatchEvent.FoulKind.PERSONAL;
    }

    private void opponentScore(MatchEvent.OpponentScore score) {
        if (!running) {
            matchWarn(WarningCode.EVENT_OUTSIDE_PERIOD, score, null, "Recorded while no period was running");
        }
        scoreboard.opponent(score.meta().period(), score.points());
    }

    private PlayerTally rosterPlayer(MatchEvent event, PlayerId player) {
        PlayerTally tally = tallies.get(player);
        if (tally == null) {
            matchWarn(WarningCode.PLAYER_NOT_IN_ROSTER, event, player, "Player is not on the match roster");
        }
        return tally;
    }

    private List<PlayerTally> onCourt() {
        return tallies.values().stream().filter(PlayerTally::onCourt).toList();
    }

    private void matchWarn(WarningCode code, MatchEvent event, PlayerId player, String message) {
        EventId id = event.id();
        matchWarnings.add(ProjectionWarning.of(code, id, player, message));
    }
}
