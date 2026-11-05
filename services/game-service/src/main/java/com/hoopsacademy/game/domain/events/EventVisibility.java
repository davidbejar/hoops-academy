package com.hoopsacademy.game.domain.events;

import com.hoopsacademy.game.domain.PlayerVisibility;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Which events of one match a viewer may read (ADR-0028, security review F-01). An event attributed to a player
 * (statistics, substitutions, a note about a player) is visible when that player is; team-level events (period start
 * and end, opponent score, timeouts, notes about nobody) are visible to everyone. A VOID is visible when the event it
 * voids is, following VOID-of-VOID chains; a VOID whose target is unknown, or that ends in a cycle of VOIDs, names no
 * player and is visible.
 */
public final class EventVisibility {

    private final Map<EventId, MatchEvent> byId = new HashMap<>();
    private final PlayerVisibility viewer;

    private EventVisibility(Collection<MatchEvent> match, PlayerVisibility viewer) {
        match.forEach(e -> byId.putIfAbsent(e.id(), e));
        this.viewer = viewer;
    }

    /** @param match every stored event of the match (VOID targets are resolved among them) */
    public static EventVisibility of(Collection<MatchEvent> match, PlayerVisibility viewer) {
        return new EventVisibility(match, viewer);
    }

    public boolean visible(MatchEvent event) {
        if (viewer.seesAll()) {
            return true;
        }
        Set<EventId> followed = new HashSet<>();
        MatchEvent current = event;
        while (current instanceof MatchEvent.Void v && followed.add(v.id())) {
            MatchEvent target = byId.get(v.target());
            if (target == null) {
                return true;
            }
            current = target;
        }
        return current.playerId().map(viewer::sees).orElse(true);
    }
}
