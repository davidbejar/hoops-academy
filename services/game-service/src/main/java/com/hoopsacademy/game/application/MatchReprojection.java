package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.projection.BoxScoreProjector;
import com.hoopsacademy.game.domain.projection.MatchRules;
import com.hoopsacademy.game.domain.projection.Projection;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.stream.Stream;
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
        return reproject(match, events.findByMatch(match.id()), List.of());
    }

    /**
     * Re-projects from events already read in this transaction (GAME-01): {@code stored}, every event of the match in
     * server order with the marks its row carries, and {@code appended} since under the match's lock (higher sequence
     * numbers, no marks yet). Writes only the {@code voided_by} marks that changed.
     */
    Projection reproject(Match match, List<StoredEvent> stored, List<RecordedEvent> appended) {
        Projection projection = project(match,
                Stream.concat(stored.stream().map(StoredEvent::recorded), appended.stream()).toList());
        projections.save(match.id(), projection);
        VoidMarks changes = VoidMarks.between(stored, projection.voidedBy());
        if (!changes.isEmpty()) {
            events.markVoided(match.id(), changes);
        }
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
