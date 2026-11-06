package com.hoopsacademy.game.adapters.out.persistence;

import static com.hoopsacademy.game.domain.events.Script.player;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.application.MatchEventRepository;
import com.hoopsacademy.game.application.Recorder;
import com.hoopsacademy.game.application.StoredEvent;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.PlayerVisibility;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.EventMeta;
import com.hoopsacademy.game.domain.events.EventVisibility;
import com.hoopsacademy.game.domain.events.MatchEvent;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.stream.IntStream;
import java.util.stream.LongStream;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * The feed query of {@link JpaMatchEventRepository} admits exactly the events {@link EventVisibility} (the domain rule,
 * ADR-0030) admits, paged by {@code after} and {@code limit} (WP60). Random matches per seed, stored for real: player and
 * team-level events, notes with and without a player, VOIDs of anything (earlier or later events, other VOIDs, itself,
 * unknown ids, an event of another match), so chains and cycles of VOIDs occur. Seeded {@link Random} instead of a jqwik
 * property: jqwik's engine does not boot Quarkus, and a failing seed is reproducible from the test name.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class FeedVisibilityQueryPropertyTest {

    static final TenantId TENANT = TenantId.parse("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa");
    static final String TEAM = "11111111-0000-4000-8000-0000000000e1";
    static final String SEASON = "22222222-0000-4000-8000-0000000000e1";
    static final Recorder RECORDER = new Recorder(UUID.fromString("33333333-0000-4000-8000-0000000000e1"), "Seeder");
    static final int PLAYERS = 6;
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, PLAYERS)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, n <= 5)).toList();

    @Inject
    MatchSeed seed;

    @Inject
    TenantScope tenantScope;

    @Inject
    MatchEventRepository events;

    static LongStream seeds() {
        return LongStream.rangeClosed(1, 60);
    }

    @ParameterizedTest(name = "seed {0}")
    @MethodSource("seeds")
    void theQueryAdmitsWhatTheDomainRuleAdmits(long seedValue) {
        Random random = new Random(seedValue);
        MatchId decoy = newMatch();
        List<EventId> decoyIds = store(decoy, randomEvents(random, List.of(), 3));
        MatchId match = newMatch();
        store(match, randomEvents(random, decoyIds, random.nextInt(41)));

        List<StoredEvent> all = inTenant(() -> events.findByMatch(match));
        for (int trial = 0; trial < 6; trial++) {
            PlayerVisibility viewer = randomViewer(random, trial);
            long after = randomCursor(random, all);
            int limit = 1 + random.nextInt(all.size() + 2);
            assertThat(inTenant(() -> events.after(match, viewer, after, limit)))
                    .as("viewer %s after %d limit %d", viewer, after, limit)
                    .containsExactlyElementsOf(expected(all, viewer, after, limit));
        }
    }

    @Test
    void chainsCyclesAndForeignTargetsFollowTheRule() {
        MatchId other = newMatch();
        Script elsewhere = Script.unique().shot(1, 500, player(2), 2, true);
        store(other, elsewhere.events().stream().map(RecordedEvent::event).toList());
        EventId cycleA = EventId.of(UUID.randomUUID()), cycleB = EventId.of(UUID.randomUUID());
        Script s = Script.unique()
                .shot(1, 590, player(2), 2, true)              // 1 hidden: another player's shot
                .shot(1, 580, player(1), 3, true);             // 2 visible: the child's shot
        EventId hiddenShot = s.events().get(0).id(), childShot = s.last();
        s.voidOf(1, 570, hiddenShot);                          // 3 hidden: follows 1
        EventId hiddenVoid = s.last();
        s.voidOf(1, 560, hiddenVoid);                          // 4 hidden: chain 4 → 3 → 1
        s.voidOf(1, 550, childShot);                           // 5 visible: follows 2
        s.voidOf(1, 540, elsewhere.last());                    // 6 visible: target in another match
        List<MatchEvent> stored = new ArrayList<>(s.events().stream().map(RecordedEvent::event).toList());
        stored.add(voidWithId(cycleA, cycleB, 7));             // 7 visible: cycle 7 → 8 → 7
        stored.add(voidWithId(cycleB, cycleA, 8));             // 8 visible: cycle 8 → 7 → 8
        stored.add(voidWithId(EventId.of(UUID.randomUUID()), null, 9)); // 9 visible: VOID of itself
        stored.add(new MatchEvent.Note(meta(EventId.of(UUID.randomUUID()), 10), null, "Referee change")); // 10 team
        stored.add(new MatchEvent.Note(meta(EventId.of(UUID.randomUUID()), 11), player(2), "Injured"));    // 11 hidden
        MatchId match = newMatch();
        List<EventId> ids = store(match, stored);
        PlayerVisibility parent = PlayerVisibility.only(List.of(player(1)));

        List<StoredEvent> all = inTenant(() -> events.findByMatch(match));
        List<StoredEvent> page = inTenant(() -> events.after(match, parent, 0, 100));

        assertThat(page).containsExactlyElementsOf(expected(all, parent, 0, 100));
        assertThat(page).extracting(e -> e.recorded().id())
                .containsExactly(ids.get(1), ids.get(4), ids.get(5), ids.get(6), ids.get(7), ids.get(8), ids.get(9));
    }

    /** The domain rule over every event of the match, then the cursor and the page size. */
    private static List<StoredEvent> expected(List<StoredEvent> all, PlayerVisibility viewer, long after, int limit) {
        EventVisibility rule = EventVisibility.of(all.stream().map(e -> e.recorded().event()).toList(), viewer);
        return all.stream()
                .filter(e -> e.recorded().serverSeq() > after)
                .filter(e -> rule.visible(e.recorded().event()))
                .limit(limit)
                .toList();
    }

    /** Every third trial sees all; the others a random subset of the roster, sometimes nobody, sometimes a stranger. */
    private static PlayerVisibility randomViewer(Random random, int trial) {
        if (trial % 3 == 2) {
            return PlayerVisibility.everyone();
        }
        List<PlayerId> visible = IntStream.rangeClosed(1, PLAYERS + 1)
                .filter(n -> random.nextInt(3) == 0)
                .mapToObj(Script::player)
                .toList();
        return PlayerVisibility.only(visible);
    }

    private static long randomCursor(Random random, List<StoredEvent> all) {
        if (all.isEmpty() || random.nextBoolean()) {
            return 0;
        }
        return all.get(random.nextInt(all.size())).recorded().serverSeq();
    }

    /** {@code size} random events; VOID targets: any event of this match (itself included), another match's, unknown. */
    private static List<MatchEvent> randomEvents(Random random, List<EventId> foreign, int size) {
        List<EventId> ids = Stream.generate(() -> EventId.of(UUID.randomUUID())).limit(size).toList();
        List<MatchEvent> events = new ArrayList<>();
        for (int i = 0; i < size; i++) {
            EventMeta meta = meta(ids.get(i), i + 1);
            PlayerId p = player(1 + random.nextInt(PLAYERS + 1));
            events.add(switch (random.nextInt(18)) {
                case 0 -> new MatchEvent.PeriodStart(meta);
                case 1 -> new MatchEvent.PeriodEnd(meta);
                case 2 -> new MatchEvent.SubIn(meta, p);
                case 3 -> new MatchEvent.SubOut(meta, p);
                case 4 -> new MatchEvent.Shot(meta, p, 1 + random.nextInt(3), random.nextBoolean());
                case 5 -> new MatchEvent.Assist(meta, p);
                case 6 -> new MatchEvent.Rebound(meta, p, MatchEvent.ReboundKind.DEFENSIVE);
                case 7 -> new MatchEvent.Turnover(meta, p);
                case 8 -> new MatchEvent.Steal(meta, p);
                case 9 -> new MatchEvent.Block(meta, p);
                case 10 -> new MatchEvent.Foul(meta, p, MatchEvent.FoulKind.PERSONAL);
                case 11 -> new MatchEvent.OpponentScore(meta, 2);
                case 12 -> new MatchEvent.Timeout(meta, MatchEvent.TimeoutSide.OPPONENT);
                case 13 -> new MatchEvent.Note(meta, random.nextBoolean() ? p : null, "note");
                default -> new MatchEvent.Void(meta, voidTarget(random, ids, foreign));
            });
        }
        return events;
    }

    private static EventId voidTarget(Random random, List<EventId> ids, List<EventId> foreign) {
        int pick = random.nextInt(10);
        if (pick == 8 && !foreign.isEmpty()) {
            return foreign.get(random.nextInt(foreign.size()));
        }
        if (pick == 9) {
            return EventId.of(UUID.randomUUID());
        }
        return ids.get(random.nextInt(ids.size()));
    }

    /** A VOID with a given id; a null target voids itself. */
    private static MatchEvent.Void voidWithId(EventId id, EventId target, long clientSeq) {
        return new MatchEvent.Void(meta(id, clientSeq), target == null ? id : target);
    }

    private static EventMeta meta(EventId id, long clientSeq) {
        return new EventMeta(id, "property", clientSeq, 1, 300, Script.BASE.plusSeconds(clientSeq));
    }

    private MatchId newMatch() {
        return MatchId.of(seed.match(TENANT.value().toString(), TEAM, SEASON, MatchStatus.LIVE,
                Instant.parse("2026-11-01T09:00:00Z"), ROSTER));
    }

    /** Appends the events in order (server sequence = list order) and returns their ids. */
    private List<EventId> store(MatchId match, List<MatchEvent> toStore) {
        tenantScope.runAs(TENANT, () -> toStore.forEach(e -> events.append(match, e, RECORDER)));
        return toStore.stream().map(MatchEvent::id).toList();
    }

    private <T> T inTenant(Supplier<T> work) {
        return tenantScope.runAs(TENANT, work);
    }
}
