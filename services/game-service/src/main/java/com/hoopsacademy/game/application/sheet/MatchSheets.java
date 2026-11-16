package com.hoopsacademy.game.application.sheet;

import com.hoopsacademy.game.application.GetBoxScore.BoxScore;
import com.hoopsacademy.game.application.GetBoxScore.VisibleLine;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.projection.MatchSummary;
import java.time.ZoneId;
import java.util.Optional;

/**
 * Builds a {@link MatchSheet} from a box score read (WP117): the match's header, the team-level figures every member
 * sees, and exactly the box score's visible lines; nothing the caller does not see in {@code getBoxScore}.
 */
final class MatchSheets {

    /** Printed when game does not know the academy's name (rest source without the replica consumer). */
    static final String UNKNOWN_ACADEMY = "Hoops Academy";
    /** Used when the caller's context carries no zone (never from core; a test or an older resolver). */
    static final ZoneId UNKNOWN_ZONE = ZoneId.of("UTC");

    private MatchSheets() {}

    static MatchSheet.Academy academy(Optional<String> name, Optional<ZoneId> zone) {
        return new MatchSheet.Academy(name.orElse(UNKNOWN_ACADEMY), zone.orElse(UNKNOWN_ZONE));
    }

    static MatchSheet of(BoxScore box, SheetLanguage language, MatchSheet.Academy academy, String teamName) {
        Match match = box.match();
        MatchSummary summary = box.projection().summary();
        return new MatchSheet(language, academy,
                new MatchSheet.Header(teamName, match.opponentName(), match.homeAway(), match.scheduledAt(),
                        match.venue(), match.status(), match.periodCount(), match.periodMinutes()),
                summary.teamScore(), summary.opponentScore(), summary.periodScores(), box.projection().teamTotals(),
                box.visibleLines().stream().map(MatchSheets::line).toList());
    }

    private static MatchSheet.Line line(VisibleLine line) {
        return new MatchSheet.Line(line.entry().displayName(), line.entry().jerseyNumber(), line.entry().starter(),
                line.stats());
    }
}
