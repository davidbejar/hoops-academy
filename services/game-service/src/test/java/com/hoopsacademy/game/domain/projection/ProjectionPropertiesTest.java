package com.hoopsacademy.game.domain.projection;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.EventMeta;
import com.hoopsacademy.game.domain.events.MatchEvent;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.stream.IntStream;
import net.jqwik.api.Arbitraries;
import net.jqwik.api.Arbitrary;
import net.jqwik.api.Combinators;
import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.Provide;

/** The projection is a pure function of the event SET: arrival order and re-delivery do not matter. */
class ProjectionPropertiesTest {

    static final MatchRules RULES = new MatchRules(4, 10, 5);
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 7)
            .mapToObj(n -> new RosterEntry(Script.player(n), "P" + n, null, n <= 5))
            .toList();

    /** One generated event before ids are assigned; {@code target} picks the VOID target among all ids (or none). */
    record Spec(int kind, int period, int clock, int player, int target, int deviceSecond) {}

    @Property(tries = 300)
    void projectionIgnoresArrivalOrderAndDuplicates(@ForAll("matches") List<RecordedEvent> events, @ForAll long seed) {
        Random random = new Random(seed);
        List<RecordedEvent> delivered = new ArrayList<>(events);
        for (RecordedEvent event : events) {
            if (random.nextInt(4) == 0) {
                delivered.add(event); // re-delivered by an offline device
            }
        }
        Collections.shuffle(delivered, random);

        assertThat(BoxScoreProjector.project(RULES, ROSTER, delivered))
                .isEqualTo(BoxScoreProjector.project(RULES, ROSTER, events));
    }

    @Provide
    Arbitrary<List<RecordedEvent>> matches() {
        Arbitrary<Spec> spec = Combinators.combine(
                        Arbitraries.integers().between(0, 14),
                        Arbitraries.integers().between(1, 6),
                        Arbitraries.integers().between(0, 650),
                        Arbitraries.integers().between(1, 8),
                        Arbitraries.integers().between(0, 80),
                        Arbitraries.integers().between(0, 40))
                .as(Spec::new);
        return spec.list().ofMaxSize(80).map(ProjectionPropertiesTest::toEvents);
    }

    private static List<RecordedEvent> toEvents(List<Spec> specs) {
        List<RecordedEvent> events = new ArrayList<>();
        for (int i = 0; i < specs.size(); i++) {
            Spec s = specs.get(i);
            long seq = i + 1L;
            EventMeta meta = new EventMeta(Script.eventId(seq), "d" + (i % 3), seq, s.period(), s.clock(),
                    Script.BASE.plusSeconds(s.deviceSecond()));
            events.add(new RecordedEvent(event(s, meta, specs.size()), seq));
        }
        return events;
    }

    private static MatchEvent event(Spec s, EventMeta meta, int size) {
        PlayerId p = Script.player(s.player());
        return switch (s.kind()) {
            case 0 -> new MatchEvent.PeriodStart(meta);
            case 1 -> new MatchEvent.PeriodEnd(meta);
            case 2 -> new MatchEvent.SubIn(meta, p);
            case 3 -> new MatchEvent.SubOut(meta, p);
            case 4 -> new MatchEvent.Shot(meta, p, 1 + s.target() % 3, s.target() % 2 == 0);
            case 5 -> new MatchEvent.Assist(meta, p);
            case 6 -> new MatchEvent.Rebound(meta, p, MatchEvent.ReboundKind.values()[s.target() % 2]);
            case 7 -> new MatchEvent.Turnover(meta, p);
            case 8 -> new MatchEvent.Steal(meta, p);
            case 9 -> new MatchEvent.Block(meta, p);
            case 10 -> new MatchEvent.Foul(meta, p, MatchEvent.FoulKind.values()[s.target() % 3]);
            case 11 -> new MatchEvent.OpponentScore(meta, 1 + s.target() % 3);
            case 12 -> new MatchEvent.Timeout(meta, MatchEvent.TimeoutSide.OPPONENT);
            case 13 -> new MatchEvent.Note(meta, p, "note");
            default -> new MatchEvent.Void(meta, voidTarget(s.target(), size));
        };
    }

    private static EventId voidTarget(int target, int size) {
        return Script.eventId(target <= size ? Math.max(1, target) : 10_000 + target);
    }
}
