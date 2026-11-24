package com.hoopsacademy.game.application.sheet;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.i18n.AppLanguage;
import com.hoopsacademy.game.application.GetBoxScore.BoxScore;
import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import com.hoopsacademy.game.domain.projection.MatchSummary;
import com.hoopsacademy.game.domain.projection.PeriodScore;
import com.hoopsacademy.game.domain.projection.PlayerLine;
import com.hoopsacademy.game.domain.projection.Projection;
import com.hoopsacademy.game.domain.projection.StatLine;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * What the match sheet prints from a box score read (WP117): the match's header, the score, the score by period and the
 * team totals as every member sees them, and exactly the player lines the caller sees in the box score.
 */
class MatchSheetsTest {

    static final PlayerId ANA = PlayerId.of(UUID.randomUUID());
    static final PlayerId BEA = PlayerId.of(UUID.randomUUID());
    static final PlayerId CAS = PlayerId.of(UUID.randomUUID());
    static final StatLine ANA_LINE = new StatLine(7, 1, 2, 3, 4, 0, 1, 2, 0, 3, 1, 1, 0, 2, 0, 0, 900);
    static final StatLine BEA_LINE = new StatLine(5, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1200);
    static final Instant TIP_OFF = Instant.parse("2026-11-14T09:00:00Z");
    static final MatchSheet.Academy ACADEMY = new MatchSheet.Academy("Garuda Hoops", ZoneId.of("Asia/Jakarta"));

    private final MatchId id = MatchId.random();
    private final Match match = Match.schedule(id, TeamId.of(UUID.randomUUID()), SeasonId.of(UUID.randomUUID()),
            "Tigers", HomeAway.AWAY, TIP_OFF, "GOR Bulungan", 4, 8, UUID.randomUUID());
    private final MatchRoster roster = new MatchRoster(id, List.of(
            new RosterEntry(ANA, "Ana Ruiz", new JerseyNumber("7"), true),
            new RosterEntry(BEA, "Bea Gómez", null, false),
            new RosterEntry(CAS, "Cas Lee", new JerseyNumber("00"), true)));
    private final Projection projection = new Projection(
            List.of(new PlayerLine(ANA, true, ANA_LINE, List.of()), new PlayerLine(BEA, false, BEA_LINE, List.of())),
            new MatchSummary(12, 9, List.of(new PeriodScore(1, 5, 4), new PeriodScore(2, 7, 5)), 42), List.of(),
            Map.of());

    private MatchSheet sheet(Set<PlayerId> visible) {
        return MatchSheets.of(new BoxScore(match, roster, projection, visible), AppLanguage.ID, ACADEMY, "U14 Elang");
    }

    @Test
    void theHeaderIsTheMatchWithItsTeamsName() {
        MatchSheet sheet = sheet(Set.of());

        assertThat(sheet.language()).isEqualTo(AppLanguage.ID);
        assertThat(sheet.academy()).isEqualTo(ACADEMY);
        assertThat(sheet.header()).isEqualTo(new MatchSheet.Header("U14 Elang", "Tigers", HomeAway.AWAY, TIP_OFF,
                "GOR Bulungan", MatchStatus.SCHEDULED, 4, 8));
    }

    @Test
    void theTeamLevelFiguresAreEveryMembersAndCountEveryPlayer() {
        MatchSheet sheet = sheet(Set.of(ANA));

        assertThat(sheet.teamScore()).isEqualTo(12);
        assertThat(sheet.opponentScore()).isEqualTo(9);
        assertThat(sheet.periodScores()).containsExactly(new PeriodScore(1, 5, 4), new PeriodScore(2, 7, 5));
        assertThat(sheet.teamTotals()).isEqualTo(ANA_LINE.plus(BEA_LINE));
    }

    @Test
    void thePlayersAreTheLinesTheCallerSeesInRosterOrder() {
        assertThat(sheet(Set.of(ANA, BEA, CAS)).players()).containsExactly(
                new MatchSheet.Line("Ana Ruiz", new JerseyNumber("7"), true, ANA_LINE),
                new MatchSheet.Line("Bea Gómez", null, false, BEA_LINE),
                new MatchSheet.Line("Cas Lee", new JerseyNumber("00"), true, StatLine.ZERO));
        assertThat(sheet(Set.of(BEA)).players()).extracting(MatchSheet.Line::displayName).containsExactly("Bea Gómez");
        assertThat(sheet(Set.of()).players()).isEmpty();
    }

    @Test
    void theAcademyIsWhatGameKnowsElseAPlainFallback() {
        assertThat(MatchSheets.academy(Optional.of("Garuda Hoops"), Optional.of(ZoneId.of("Asia/Jakarta"))))
                .isEqualTo(ACADEMY);
        assertThat(MatchSheets.academy(Optional.empty(), Optional.empty()))
                .isEqualTo(new MatchSheet.Academy("Hoops Academy", ZoneId.of("UTC")));
    }
}
