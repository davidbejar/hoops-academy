package com.hoopsacademy.game.domain.projection;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SeasonStatsTest {

    static final PlayerId PLAYER = PlayerId.of(UUID.randomUUID());
    static final SeasonId SEASON = SeasonId.of(UUID.randomUUID());

    static StatLine line(int points, int assists, int oreb, int dreb, int seconds) {
        return new StatLine(points, 0, 0, points / 2, points / 2, 0, 0, assists, oreb, dreb, 1, 0, 0, 2, 0, 0, seconds);
    }

    static SeasonLine match(boolean starter, StatLine stats) {
        return new SeasonLine(MatchId.random(), Instant.parse("2026-11-01T10:00:00Z"), "Rivals", MatchStatus.FINISHED,
                starter, stats);
    }

    @Test
    void totalsSumEveryMatchAndAveragesUseGamesPlayed() {
        SeasonLine first = match(true, line(10, 2, 1, 3, 1200));
        SeasonLine second = match(false, line(5, 1, 0, 1, 600));
        SeasonLine benched = match(false, StatLine.ZERO);

        SeasonStats stats = SeasonStats.of(PLAYER, SEASON, List.of(first, second, benched));

        assertThat(stats.gamesPlayed()).isEqualTo(2);
        assertThat(stats.gamesStarted()).isEqualTo(1);
        assertThat(stats.totals().points()).isEqualTo(15);
        assertThat(stats.totals().secondsPlayed()).isEqualTo(1800);
        assertThat(stats.averages().points()).isEqualTo(7.5);
        assertThat(stats.averages().rebounds()).isEqualTo(2.5);
        assertThat(stats.averages().assists()).isEqualTo(1.5);
        assertThat(stats.averages().turnovers()).isEqualTo(1.0);
        assertThat(stats.averages().personalFouls()).isEqualTo(2.0);
        assertThat(stats.averages().minutesPlayed()).isEqualTo(15.0);
        assertThat(stats.matches()).containsExactly(first, second, benched);
    }

    @Test
    void averagesAreRoundedToTwoDecimalsAndZeroWithoutGames() {
        SeasonStats three = SeasonStats.of(PLAYER, SEASON, List.of(
                match(true, line(1, 0, 0, 0, 10)), match(true, line(1, 0, 0, 0, 10)), match(true, line(0, 0, 0, 0, 0))));
        SeasonStats none = SeasonStats.of(PLAYER, SEASON, List.of());

        assertThat(three.averages().points()).isEqualTo(0.67);
        assertThat(three.averages().minutesPlayed()).isEqualTo(0.11);
        assertThat(none.gamesPlayed()).isZero();
        assertThat(none.averages()).isEqualTo(new SeasonStats.Averages(0, 0, 0, 0, 0, 0, 0, 0));
        assertThat(none.totals()).isEqualTo(StatLine.ZERO);
    }
}
