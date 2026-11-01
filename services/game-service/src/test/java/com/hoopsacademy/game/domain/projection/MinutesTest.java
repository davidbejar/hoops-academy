package com.hoopsacademy.game.domain.projection;

import static com.hoopsacademy.game.domain.events.Script.player;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.Script;
import java.util.List;
import java.util.function.Supplier;
import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/** Seconds played derived from starters, period and substitution events (2 periods of 10 min, OT 5 min). */
class MinutesTest {

    static final MatchRules RULES = new MatchRules(2, 10, 5);
    static final PlayerId P1 = player(1), P2 = player(2);
    static final List<RosterEntry> ROSTER = List.of(
            new RosterEntry(P1, "Starter", null, true), new RosterEntry(P2, "Bench", null, false));

    static Stream<Arguments> cases() {
        return Stream.of(
                row("starter plays the whole game", () -> new Script()
                        .start(1, 600).end(1, 0).start(2, 600).end(2, 0), 1200, 0),
                row("starter out and back in", () -> new Script()
                        .start(1, 600).subOut(1, 400, P1).subIn(1, 400, P2)
                        .subIn(1, 100, P1).subOut(1, 100, P2).end(1, 0), 300, 300),
                row("substitution between periods", () -> new Script()
                        .start(1, 600).end(1, 0).subOut(2, 600, P1).subIn(2, 600, P2).start(2, 600).end(2, 0), 600, 600),
                row("substitution before the opening tip", () -> new Script()
                        .subOut(1, 600, P1).subIn(1, 600, P2).start(1, 600).end(1, 0), 0, 600),
                row("overtime uses the overtime length", () -> new Script()
                        .start(1, 600).end(1, 0).start(2, 600).end(2, 0).start(3, 300).end(3, 0), 1500, 0),
                row("missing SUB_OUT is a warning, the player keeps playing", () -> new Script()
                        .start(1, 600).subIn(1, 400, P2).subOut(1, 200, P2).subIn(1, 200, P1).end(1, 0), 600, 200,
                        "SUB_IN_PLAYER_ON_COURT"),
                row("missing PERIOD_END closes the period at 0:00", () -> new Script()
                        .start(1, 600).start(2, 600).end(2, 0), 1200, 0, "MISSING_PERIOD_END"),
                row("running period counts up to the latest event", () -> new Script()
                        .start(1, 600).shot(1, 450, P1, 2, true), 150, 0),
                row("clock beyond the period length is clamped", () -> new Script()
                        .start(1, 900).end(1, 0), 600, 0, "CLOCK_OUT_OF_RANGE"),
                row("no period events, no minutes", () -> new Script()
                        .subIn(1, 300, P2).subOut(1, 100, P2), 0, 0));
    }

    private static Arguments row(String name, Supplier<Script> script, int p1Seconds, int p2Seconds, String... warnings) {
        return Arguments.of(name, script, p1Seconds, p2Seconds, List.of(warnings));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("cases")
    void secondsPlayed(String name, Supplier<Script> script, int p1Seconds, int p2Seconds, List<String> warnings) {
        Projection p = BoxScoreProjector.project(RULES, ROSTER, script.get().events());

        assertThat(p.playerStats().get(0).stats().secondsPlayed()).as("P1").isEqualTo(p1Seconds);
        assertThat(p.playerStats().get(1).stats().secondsPlayed()).as("P2").isEqualTo(p2Seconds);
        Stream<ProjectionWarning> all = Stream.concat(p.warnings().stream(),
                p.playerStats().stream().flatMap(l -> l.warnings().stream()));
        assertThat(all.map(ProjectionWarning::code).toList()).containsExactlyElementsOf(warnings);
    }
}
