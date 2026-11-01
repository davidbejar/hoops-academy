package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.EventOrdering;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import java.util.Collection;
import java.util.List;

/**
 * Pure projection of a match's events into the box score. The result depends only on the SET of events (by id):
 * arrival order and duplicates are irrelevant, because events are replayed in {@link EventOrdering#GAME_ORDER}.
 */
public final class BoxScoreProjector {

    private BoxScoreProjector() {}

    public static Projection project(MatchRules rules, List<RosterEntry> roster, Collection<RecordedEvent> events) {
        List<RecordedEvent> gameOrder = EventOrdering.canonical(events);
        VoidResolution voids = VoidResolution.resolve(gameOrder);
        ProjectionRun run = new ProjectionRun(rules, roster);
        gameOrder.stream().filter(e -> !voids.excludes(e)).forEach(e -> run.apply(e.event()));
        long lastServerSeq = gameOrder.stream().mapToLong(RecordedEvent::serverSeq).max().orElse(0L);
        return run.finish(lastServerSeq, voids);
    }
}
