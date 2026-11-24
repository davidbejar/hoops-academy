package com.hoopsacademy.game.application.sheet;

import com.hoopsacademy.common.i18n.AppLanguage;
import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.projection.PeriodScore;
import com.hoopsacademy.game.domain.projection.StatLine;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Objects;

/**
 * What a match sheet prints (decisions 89 and 90, ADR-0048 amendment of WP117): the box score one caller sees, with the
 * match's header, in that caller's language. {@code players} holds only the lines the caller sees in the box score.
 */
public record MatchSheet(AppLanguage language, Academy academy, Header header, int teamScore, int opponentScore,
        List<PeriodScore> periodScores, StatLine teamTotals, List<Line> players) {

    public MatchSheet {
        Objects.requireNonNull(language, "language");
        Objects.requireNonNull(academy, "academy");
        Objects.requireNonNull(header, "header");
        Objects.requireNonNull(teamTotals, "teamTotals");
        periodScores = List.copyOf(periodScores);
        players = List.copyOf(players);
    }

    /** The academy printed above the title; every date and time is printed in its zone. */
    public record Academy(String name, ZoneId timeZone) {}

    /** The match: our team, the opponent, when and where, its state and periods. */
    public record Header(String teamName, String opponentName, HomeAway homeAway, Instant scheduledAt, String venue,
            MatchStatus status, int periodCount, int periodMinutes) {}

    /** One player's line; {@code jerseyNumber} is null when the roster gave none. */
    public record Line(String displayName, JerseyNumber jerseyNumber, boolean starter, StatLine stats) {}
}
