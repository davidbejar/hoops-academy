package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Which events are voided, decided before the replay so the result does not depend on arrival order. A VOID of a
 * VOID is ignored with a warning (re-enter the event instead); a VOID of an unknown event is a warning.
 */
record VoidResolution(Map<EventId, EventId> voidedBy, List<ProjectionWarning> warnings) {

    static VoidResolution resolve(List<RecordedEvent> gameOrder) {
        Map<EventId, MatchEvent> byId = new HashMap<>();
        gameOrder.forEach(e -> byId.put(e.id(), e.event()));
        Map<EventId, EventId> voidedBy = new LinkedHashMap<>();
        List<ProjectionWarning> warnings = new ArrayList<>();
        for (RecordedEvent recorded : gameOrder) {
            if (recorded.event() instanceof MatchEvent.Void v) {
                MatchEvent target = byId.get(v.target());
                if (target == null) {
                    warnings.add(ProjectionWarning.of(WarningCode.VOID_TARGET_NOT_FOUND, v.id(), null,
                            "Voided event " + v.target() + " is unknown"));
                } else if (target instanceof MatchEvent.Void) {
                    warnings.add(ProjectionWarning.of(WarningCode.VOID_OF_VOID, v.id(), null,
                            "A VOID cannot be voided; enter the event again instead"));
                } else {
                    voidedBy.putIfAbsent(v.target(), v.id());
                }
            }
        }
        return new VoidResolution(voidedBy, warnings);
    }

    boolean excludes(RecordedEvent recorded) {
        return recorded.event() instanceof MatchEvent.Void || voidedBy.containsKey(recorded.id());
    }
}
