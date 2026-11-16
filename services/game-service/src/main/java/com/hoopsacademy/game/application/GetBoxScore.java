package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.PlayerVisibility;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.projection.PlayerLine;
import com.hoopsacademy.game.domain.projection.Projection;
import com.hoopsacademy.game.domain.projection.ProjectionWarning;
import com.hoopsacademy.game.domain.projection.StatLine;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Box score from the stored projection (contract getBoxScore). Player lines follow {@link StatVisibility} (ADMIN and
 * staff of the team all, a PARENT linked players, a PLAYER their own); scores, totals and match warnings are visible to
 * every member. A match without events is projected on the fly (all zeros).
 */
@ApplicationScoped
public class GetBoxScore {

    public record BoxScore(Match match, MatchRoster roster, Projection projection, Set<PlayerId> visiblePlayers) {

        /**
         * The lines the caller sees, in roster order: a visible roster player's statistics and warnings (zero and none
         * when the projection has no line for them). The box score and the match sheet print exactly these.
         */
        public List<VisibleLine> visibleLines() {
            Map<PlayerId, PlayerLine> lines = projection.playerStats().stream()
                    .collect(Collectors.toMap(PlayerLine::playerId, Function.identity()));
            return roster.entries().stream().filter(entry -> visiblePlayers.contains(entry.playerId()))
                    .map(entry -> VisibleLine.of(entry, lines.get(entry.playerId()))).toList();
        }
    }

    /** One visible roster player's line of the box score. */
    public record VisibleLine(RosterEntry entry, StatLine stats, List<ProjectionWarning> warnings) {

        static VisibleLine of(RosterEntry entry, PlayerLine line) {
            return line == null ? new VisibleLine(entry, StatLine.ZERO, List.of())
                    : new VisibleLine(entry, line.stats(), line.warnings());
        }
    }

    private final MatchLookup lookup;
    private final MatchRepository matches;
    private final ProjectionRepository projections;
    private final MatchReprojection reprojection;
    private final CurrentCaller caller;

    GetBoxScore(MatchLookup lookup, MatchRepository matches, ProjectionRepository projections,
            MatchReprojection reprojection, CurrentCaller caller) {
        this.lookup = lookup;
        this.matches = matches;
        this.projections = projections;
        this.reprojection = reprojection;
        this.caller = caller;
    }

    @Transactional
    public BoxScore handle(MatchId matchId) {
        Match match = lookup.require(matchId);
        MatchRoster roster = matches.roster(matchId);
        Projection projection = projections.find(matchId).orElseGet(() -> reprojection.project(match, List.of()));
        return new BoxScore(match, roster, projection, visiblePlayers(match, roster));
    }

    private Set<PlayerId> visiblePlayers(Match match, MatchRoster roster) {
        PlayerVisibility viewer = StatVisibility.forTeam(caller.authz(), match.teamId());
        return roster.entries().stream().map(RosterEntry::playerId).filter(viewer::sees)
                .collect(Collectors.toUnmodifiableSet());
    }
}
