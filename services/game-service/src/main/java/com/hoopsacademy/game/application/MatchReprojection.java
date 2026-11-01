package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.projection.BoxScoreProjector;
import com.hoopsacademy.game.domain.projection.MatchRules;
import com.hoopsacademy.game.domain.projection.Projection;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/** Re-projects a whole match from its roster and all its events; runs inside the caller's transaction. */
@ApplicationScoped
public class MatchReprojection {

    private final MatchRepository matches;
    private final MatchEventRepository events;
    private final ProjectionRepository projections;
    private final int overtimeMinutes;

    MatchReprojection(MatchRepository matches, MatchEventRepository events, ProjectionRepository projections,
            @ConfigProperty(name = "hoops.game.overtime-minutes", defaultValue = "5") int overtimeMinutes) {
        this.matches = matches;
        this.events = events;
        this.projections = projections;
        this.overtimeMinutes = overtimeMinutes;
    }

    public Projection reproject(Match match) {
        Projection projection = project(match, events.findByMatch(match.id()).stream().map(StoredEvent::recorded).toList());
        projections.save(match.id(), projection);
        events.markVoided(match.id(), projection.voidedBy());
        return projection;
    }

    /** Projection of the given events without storing it. */
    Projection project(Match match, List<RecordedEvent> recorded) {
        return BoxScoreProjector.project(rules(match), matches.roster(match.id()).entries(), recorded);
    }

    MatchRules rules(Match match) {
        return MatchRules.of(match, overtimeMinutes);
    }
}
