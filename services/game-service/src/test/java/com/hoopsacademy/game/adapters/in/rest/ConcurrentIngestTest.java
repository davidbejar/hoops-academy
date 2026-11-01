package com.hoopsacademy.game.adapters.in.rest;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.MatchEvent.ReboundKind;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.EventBatches;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Ingest and match updates under real concurrency against Postgres (no deadlock, no 500, sequential result). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class ConcurrentIngestTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String TEAM = "11111111-0000-4000-8000-000000000091";
    static final String SEASON = "22222222-0000-4000-8000-000000000091";
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 8)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, n <= 5)).toList();

    @Inject
    MatchSeed seed;

    /** A realistic 60-event script; same content every call, fresh ids. */
    static Script game() {
        Script s = Script.unique().start(1, 600);
        for (int i = 0; i < 28; i++) {
            int clock = 590 - i * 20;
            int shooter = 1 + i % 5;
            s.shot(1, clock, player(shooter), 2 + i % 2, i % 3 != 0);
            if (i % 7 == 0) {
                s.subOut(1, clock - 5, player(shooter)).subIn(1, clock - 5, player(6 + i % 3));
                s.subOut(1, clock - 6, player(6 + i % 3)).subIn(1, clock - 6, player(shooter));
            } else if (i % 2 == 0) {
                s.rebound(1, clock - 1, player(1 + (i + 1) % 5), ReboundKind.DEFENSIVE);
            } else {
                s.opponent(1, clock - 2, 2);
            }
        }
        return s.end(1, 0);
    }

    static Response post(UUID match, List<RecordedEvent> events) {
        return given().urlEncodingEnabled(false).header("X-Tenant-Id", A).contentType(ContentType.JSON)
                .body(EventBatches.batch(events)).post("/api/game/matches/" + match + "/events:batch");
    }

    static JsonNode boxScoreWithoutIdentity(UUID match) throws Exception {
        ObjectNode box = (ObjectNode) EventBatches.JSON.readTree(
                given().header("X-Tenant-Id", A).get("/api/game/matches/" + match + "/box-score").asString());
        box.remove(List.of("matchId", "lastServerSeq"));
        return box;
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void overlappingBatchesPostedConcurrentlyEqualTheSequentialReplay() throws Exception {
        UUID sequential = seed.match(A, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-01T10:00:00Z"), ROSTER);
        assertThat(post(sequential, game().events()).statusCode()).isEqualTo(200);
        JsonNode expected = boxScoreWithoutIdentity(sequential);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            for (int round = 0; round < 5; round++) {
                UUID match = seed.match(A, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-01T10:00:00Z"), ROSTER);
                List<RecordedEvent> events = game().events();
                int third = events.size() / 3;
                List<RecordedEvent> first = events.subList(0, 2 * third);   // overlaps the second in the middle third
                List<RecordedEvent> second = new ArrayList<>(events.subList(third, events.size()));
                java.util.Collections.reverse(second);                     // arrives in another order, too

                CyclicBarrier start = new CyclicBarrier(2);
                CompletableFuture<Response> a = CompletableFuture.supplyAsync(afterBarrier(start, () -> post(match, first)), pool);
                CompletableFuture<Response> b = CompletableFuture.supplyAsync(afterBarrier(start, () -> post(match, second)), pool);
                Response ra = a.get(30, TimeUnit.SECONDS); // a deadlock would time out here
                Response rb = b.get(30, TimeUnit.SECONDS);

                assertThat(List.of(ra.statusCode(), rb.statusCode())).containsOnly(200);
                Map<String, List<String>> outcomes = new HashMap<>();
                Map<String, Integer> seqs = new HashMap<>();
                for (Response r : List.of(ra, rb)) {
                    List<Map<String, Object>> results = r.jsonPath().getList("results");
                    for (Map<String, Object> result : results) {
                        String id = (String) result.get("eventId");
                        outcomes.computeIfAbsent(id, k -> new ArrayList<>()).add((String) result.get("status"));
                        Integer seq = (Integer) result.get("serverSeq");
                        assertThat(seqs.putIfAbsent(id, seq)).as("one serverSeq per event").isIn(null, seq);
                    }
                }
                assertThat(outcomes).hasSize(events.size());
                assertThat(outcomes.values()).allSatisfy(statuses ->
                        assertThat(statuses.stream().filter("ACCEPTED"::equals).count()).isEqualTo(1));
                assertThat(boxScoreWithoutIdentity(match)).as("round " + round).isEqualTo(expected);
            }
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void concurrentEditsOfOneMatchAreConflictsNotServerErrors() throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        List<Integer> statuses = new ArrayList<>();
        try {
            for (int round = 0; round < 10; round++) {
                UUID match = seed.match(A, TEAM, SEASON, MatchStatus.SCHEDULED, Instant.parse("2026-11-01T10:00:00Z"), ROSTER);
                CyclicBarrier start = new CyclicBarrier(2);
                List<CompletableFuture<Integer>> edits = List.of("Hall A", "Hall B").stream()
                        .map(venue -> CompletableFuture.supplyAsync(afterBarrier(start, () -> given()
                                .header("X-Tenant-Id", A).contentType(ContentType.JSON)
                                .body("{\"venue\":\"" + venue + "\"}").patch("/api/game/matches/" + match)
                                .statusCode()), pool))
                        .toList();
                for (CompletableFuture<Integer> edit : edits) {
                    statuses.add(edit.get(30, TimeUnit.SECONDS));
                }
            }
        } finally {
            pool.shutdownNow();
        }
        assertThat(statuses).containsOnly(200, 409).contains(200);
    }

    private static <T> Supplier<T> afterBarrier(CyclicBarrier barrier, Supplier<T> work) {
        return () -> {
            try {
                barrier.await(10, TimeUnit.SECONDS);
            } catch (Exception e) {
                throw new IllegalStateException(e);
            }
            return work.get();
        };
    }
}
