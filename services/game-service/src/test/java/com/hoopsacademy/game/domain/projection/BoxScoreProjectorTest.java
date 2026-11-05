package com.hoopsacademy.game.domain.projection;

import static com.hoopsacademy.game.domain.events.Script.player;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent.FoulKind;
import com.hoopsacademy.game.domain.events.MatchEvent.ReboundKind;
import com.hoopsacademy.game.domain.events.Script;
import java.util.List;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

class BoxScoreProjectorTest {

    static final MatchRules RULES = new MatchRules(4, 10, 5);
    static final PlayerId P1 = player(1), P2 = player(2), P3 = player(3), P4 = player(4), P5 = player(5), P6 = player(6);
    static final PlayerId STRANGER = player(99);

    /** P1..P5 start, P6 on the bench. */
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 6)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, n <= 5))
            .toList();

    private static Projection project(Script script) {
        return BoxScoreProjector.project(RULES, ROSTER, script.events());
    }

    private static PlayerLine line(Projection projection, PlayerId id) {
        return projection.playerStats().stream().filter(l -> l.playerId().equals(id)).findFirst().orElseThrow();
    }

    private static List<String> codes(List<ProjectionWarning> warnings) {
        return warnings.stream().map(ProjectionWarning::code).toList();
    }

    @Test
    void countsEveryStatisticAndBuildsTheScore() {
        Script s = new Script().start(1, 600)
                .shot(1, 590, P1, 2, true).shot(1, 580, P1, 3, false).shot(1, 570, P1, 1, true)
                .assist(1, 570, P2).rebound(1, 560, P3, ReboundKind.OFFENSIVE).rebound(1, 550, P3, ReboundKind.DEFENSIVE)
                .turnover(1, 540, P4).steal(1, 530, P5).block(1, 520, P5)
                .foul(1, 510, P1, FoulKind.PERSONAL).foul(1, 500, P1, FoulKind.TECHNICAL)
                .foul(1, 490, P2, FoulKind.UNSPORTSMANLIKE)
                .opponent(1, 480, 3).timeout(1, 470).note(1, 460, "good defence")
                .end(1, 0);

        Projection p = project(s);

        StatLine p1 = line(p, P1).stats();
        assertThat(p1.points()).isEqualTo(3);
        assertThat(List.of(p1.fg1Made(), p1.fg1Attempted(), p1.fg2Made(), p1.fg2Attempted(), p1.fg3Made(), p1.fg3Attempted()))
                .containsExactly(1, 1, 1, 1, 0, 1);
        assertThat(p1.personalFouls()).isEqualTo(2);
        assertThat(p1.technicalFouls()).isEqualTo(1);
        assertThat(line(p, P2).stats().assists()).isEqualTo(1);
        assertThat(line(p, P2).stats().unsportsmanlikeFouls()).isEqualTo(1);
        assertThat(line(p, P2).stats().personalFouls()).isEqualTo(1);
        assertThat(line(p, P3).stats().offensiveRebounds()).isEqualTo(1);
        assertThat(line(p, P3).stats().defensiveRebounds()).isEqualTo(1);
        assertThat(line(p, P4).stats().turnovers()).isEqualTo(1);
        assertThat(line(p, P5).stats().steals()).isEqualTo(1);
        assertThat(line(p, P5).stats().blocks()).isEqualTo(1);
        assertThat(line(p, P1).stats().secondsPlayed()).isEqualTo(600);
        assertThat(line(p, P6).stats().secondsPlayed()).isZero();
        assertThat(line(p, P1).wasStarter()).isTrue();
        assertThat(line(p, P6).wasStarter()).isFalse();

        assertThat(p.summary().teamScore()).isEqualTo(3);
        assertThat(p.summary().opponentScore()).isEqualTo(3);
        assertThat(p.summary().periodScores()).containsExactly(
                new PeriodScore(1, 3, 3), new PeriodScore(2, 0, 0), new PeriodScore(3, 0, 0), new PeriodScore(4, 0, 0));
        assertThat(p.summary().lastServerSeq()).isEqualTo(17);
        assertThat(p.warnings()).isEmpty();
        assertThat(p.playerStats()).allSatisfy(l -> assertThat(l.warnings()).isEmpty());
        assertThat(p.teamTotals().points()).isEqualTo(3);
        assertThat(p.teamTotals().secondsPlayed()).isEqualTo(3000);
    }

    @Test
    void playerLinesFollowTheRosterOrderAndAnEmptyMatchProjectsZeros() {
        Projection p = BoxScoreProjector.project(RULES, ROSTER, List.of());

        assertThat(p.playerStats()).extracting(PlayerLine::playerId).containsExactly(P1, P2, P3, P4, P5, P6);
        assertThat(p.playerStats()).allSatisfy(l -> assertThat(l.stats()).isEqualTo(StatLine.ZERO));
        assertThat(p.summary().lastServerSeq()).isZero();
        assertThat(p.summary().periodScores()).hasSize(4);
        assertThat(p.voidedBy()).isEmpty();
    }

    @Test
    void scoresByPeriodIncludeOvertime() {
        Script s = new Script().start(1, 600).shot(1, 500, P1, 2, true).end(1, 0)
                .start(5, 300).shot(5, 100, P2, 3, true).opponent(5, 50, 1).end(5, 0);

        Projection p = project(s);

        assertThat(p.summary().periodScores()).hasSize(5).last().isEqualTo(new PeriodScore(5, 3, 1));
        assertThat(p.summary().teamScore()).isEqualTo(5);
    }

    @Test
    void voidRemovesTheTargetFromEveryProjection() {
        Script s = new Script().start(1, 600).shot(1, 500, P1, 3, true);
        EventId shot = s.last();
        s.voidOf(1, 480, shot);
        EventId theVoid = s.last();

        Projection p = project(s);

        assertThat(line(p, P1).stats().points()).isZero();
        assertThat(line(p, P1).stats().fg3Attempted()).isZero();
        assertThat(p.summary().teamScore()).isZero();
        assertThat(p.voidedBy()).containsEntry(shot, theVoid).hasSize(1);
        assertThat(p.summary().lastServerSeq()).isEqualTo(3);
    }

    @Test
    void aVoidItselfNeverMovesTheClockOrThePeriods() {
        Script s = new Script().start(1, 600).shot(1, 500, P1, 2, true);
        s.voidOf(2, 700, s.last()).end(1, 0);

        Projection p = project(s);

        assertThat(p.warnings()).isEmpty();
        assertThat(line(p, P1).stats().secondsPlayed()).isEqualTo(600);
        assertThat(p.summary().periodScores()).hasSize(4);
    }

    @Test
    void voidOfAVoidIsIgnoredWithAWarningAndTheFirstVoidStillApplies() {
        Script s = new Script().start(1, 600).shot(1, 500, P1, 2, true);
        EventId shot = s.last();
        s.voidOf(1, 490, shot);
        EventId firstVoid = s.last();
        s.voidOf(1, 480, firstVoid);

        Projection p = project(s);

        assertThat(line(p, P1).stats().points()).isZero();
        assertThat(codes(p.warnings())).containsExactly("VOID_OF_VOID");
        assertThat(p.warnings().get(0).eventId()).isEqualTo(s.last());
        assertThat(p.voidedBy()).containsOnlyKeys(shot);
    }

    @Test
    void voidOfAnUnknownEventIsAWarning() {
        Script s = new Script().start(1, 600).voidOf(1, 500, Script.eventId(777));

        assertThat(codes(project(s).warnings())).containsExactly("VOID_TARGET_NOT_FOUND");
    }

    @Test
    void twoVoidsOfTheSameEventRecordTheEarliestAsVoidingEvent() {
        Script s = new Script().start(1, 600).shot(1, 500, P1, 2, true);
        EventId shot = s.last();
        s.voidOf(1, 490, shot);
        EventId first = s.last();
        s.voidOf(1, 480, shot);

        Projection p = project(s);

        assertThat(p.voidedBy()).containsExactlyEntriesOf(java.util.Map.of(shot, first));
        assertThat(p.warnings()).isEmpty();
    }

    @Test
    void impossibleSequencesBecomeWarningsNeverFailures() {
        Script s = new Script().start(1, 600)
                .subIn(1, 590, P1)               // already on court
                .subOut(1, 580, P6)              // on the bench
                .shot(1, 570, P6, 2, true)       // not on court
                .shot(1, 560, STRANGER, 2, true) // not on the roster
                .subIn(1, 550, P6)               // a sixth player on court
                .end(1, 0)
                .rebound(1, 0, P2, ReboundKind.DEFENSIVE); // after the period ended

        Projection p = project(s);

        assertThat(codes(line(p, P1).warnings())).containsExactly("SUB_IN_PLAYER_ON_COURT");
        assertThat(codes(line(p, P6).warnings())).containsExactly("SUB_OUT_PLAYER_NOT_ON_COURT", "PLAYER_NOT_ON_COURT");
        assertThat(codes(line(p, P2).warnings())).containsExactly("EVENT_OUTSIDE_PERIOD");
        assertThat(codes(p.warnings())).containsExactly("PLAYER_NOT_IN_ROSTER", "TOO_MANY_PLAYERS_ON_COURT");
        assertThat(p.warnings().get(0).playerId()).isEqualTo(STRANGER);
        // counted anyway: the bench shot, the stranger's points (team score only) and the late rebound
        assertThat(line(p, P6).stats().points()).isEqualTo(2);
        assertThat(p.summary().teamScore()).isEqualTo(4);
        assertThat(p.teamTotals().points()).isEqualTo(2);
        assertThat(line(p, P2).stats().defensiveRebounds()).isEqualTo(1);
    }

    @Test
    void benchTechnicalFoulIsNotAnOnCourtWarning() {
        Script s = new Script().start(1, 600).foul(1, 500, P6, FoulKind.TECHNICAL).foul(1, 400, P6, FoulKind.PERSONAL);

        Projection p = project(s);

        assertThat(codes(line(p, P6).warnings())).containsExactly("PLAYER_NOT_ON_COURT");
        assertThat(line(p, P6).stats().personalFouls()).isEqualTo(2);
    }

    @Test
    void periodEventsOutOfPlaceAreWarnings() {
        Script s = new Script().end(1, 0).start(1, 600).start(1, 550).end(1, 0).start(1, 0).opponent(1, 0, 2);

        Projection p = project(s);

        assertThat(codes(p.warnings())).containsExactly(
                "PERIOD_ALREADY_RUNNING", "PERIOD_NOT_RUNNING", "PERIOD_ALREADY_PLAYED", "EVENT_OUTSIDE_PERIOD");
        assertThat(p.summary().opponentScore()).isEqualTo(2);
        assertThat(line(p, P1).stats().secondsPlayed()).isEqualTo(600);
    }
}
