package com.hoopsacademy.game.domain.events;

import com.hoopsacademy.game.domain.PlayerId;
import java.util.Objects;
import java.util.Optional;

/** An append-only match event; one record per contract type. Facts only: no consistency rules live here. */
public sealed interface MatchEvent {

    EventMeta meta();

    MatchEventType type();

    /** The player the event is attributed to, if any. */
    default Optional<PlayerId> playerId() {
        return Optional.empty();
    }

    default EventId id() {
        return meta().id();
    }

    /** Player-attributed counting statistic: the only events a linked PARENT may enter. */
    sealed interface PlayerStat extends MatchEvent {

        PlayerId player();

        @Override
        default Optional<PlayerId> playerId() {
            return Optional.of(player());
        }
    }

    enum ReboundKind { OFFENSIVE, DEFENSIVE }

    enum FoulKind { PERSONAL, TECHNICAL, UNSPORTSMANLIKE }

    enum TimeoutSide { OWN, OPPONENT }

    record PeriodStart(EventMeta meta) implements MatchEvent {
        public MatchEventType type() { return MatchEventType.PERIOD_START; }
    }

    record PeriodEnd(EventMeta meta) implements MatchEvent {
        public MatchEventType type() { return MatchEventType.PERIOD_END; }
    }

    record SubIn(EventMeta meta, PlayerId player) implements MatchEvent {
        public SubIn { Objects.requireNonNull(player, "player"); }
        public MatchEventType type() { return MatchEventType.SUB_IN; }
        @Override public Optional<PlayerId> playerId() { return Optional.of(player); }
    }

    record SubOut(EventMeta meta, PlayerId player) implements MatchEvent {
        public SubOut { Objects.requireNonNull(player, "player"); }
        public MatchEventType type() { return MatchEventType.SUB_OUT; }
        @Override public Optional<PlayerId> playerId() { return Optional.of(player); }
    }

    /** @param points 1 = free throw, 2 = field goal, 3 = three-pointer */
    record Shot(EventMeta meta, PlayerId player, int points, boolean made) implements PlayerStat {
        public Shot {
            Objects.requireNonNull(player, "player");
            if (points < 1 || points > 3) {
                throw new IllegalArgumentException("points must be 1, 2 or 3");
            }
        }
        public MatchEventType type() { return MatchEventType.SHOT; }
    }

    record Assist(EventMeta meta, PlayerId player) implements PlayerStat {
        public Assist { Objects.requireNonNull(player, "player"); }
        public MatchEventType type() { return MatchEventType.ASSIST; }
    }

    record Rebound(EventMeta meta, PlayerId player, ReboundKind kind) implements PlayerStat {
        public Rebound {
            Objects.requireNonNull(player, "player");
            Objects.requireNonNull(kind, "kind");
        }
        public MatchEventType type() { return MatchEventType.REBOUND; }
    }

    record Turnover(EventMeta meta, PlayerId player) implements PlayerStat {
        public Turnover { Objects.requireNonNull(player, "player"); }
        public MatchEventType type() { return MatchEventType.TURNOVER; }
    }

    record Steal(EventMeta meta, PlayerId player) implements PlayerStat {
        public Steal { Objects.requireNonNull(player, "player"); }
        public MatchEventType type() { return MatchEventType.STEAL; }
    }

    record Block(EventMeta meta, PlayerId player) implements PlayerStat {
        public Block { Objects.requireNonNull(player, "player"); }
        public MatchEventType type() { return MatchEventType.BLOCK; }
    }

    record Foul(EventMeta meta, PlayerId player, FoulKind kind) implements PlayerStat {
        public Foul {
            Objects.requireNonNull(player, "player");
            Objects.requireNonNull(kind, "kind");
        }
        public MatchEventType type() { return MatchEventType.FOUL; }
    }

    record OpponentScore(EventMeta meta, int points) implements MatchEvent {
        public OpponentScore {
            if (points < 1 || points > 3) {
                throw new IllegalArgumentException("points must be 1, 2 or 3");
            }
        }
        public MatchEventType type() { return MatchEventType.OPPONENT_SCORE; }
    }

    record Timeout(EventMeta meta, TimeoutSide side) implements MatchEvent {
        public Timeout { Objects.requireNonNull(side, "side"); }
        public MatchEventType type() { return MatchEventType.TIMEOUT; }
    }

    /** Cancels the effect of {@code target} in every projection. */
    record Void(EventMeta meta, EventId target) implements MatchEvent {
        public Void { Objects.requireNonNull(target, "target"); }
        public MatchEventType type() { return MatchEventType.VOID; }
    }

    /** Free text, optionally about a player (null when not); no effect on statistics. */
    record Note(EventMeta meta, PlayerId player, String text) implements MatchEvent {
        public Note { Objects.requireNonNull(text, "text"); }
        public MatchEventType type() { return MatchEventType.NOTE; }
        @Override public Optional<PlayerId> playerId() { return Optional.ofNullable(player); }
    }
}
