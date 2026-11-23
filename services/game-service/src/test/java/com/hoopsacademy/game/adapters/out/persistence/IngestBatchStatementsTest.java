package com.hoopsacademy.game.adapters.out.persistence;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.EventBatches;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.mockito.InjectSpy;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/**
 * An event batch reads the match's events once and re-projects from them (GAME-01, WP126): no second read, no score
 * query under the lock, and only the {@code voided_by} marks that changed are written, in one batch statement (a VOID's
 * target may arrive after the VOID, so a batch without a VOID can change a mark too). Statements are counted on the
 * repositories' JDBC funnel, which the spies record.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class IngestBatchStatementsTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String TEAM = "11111111-0000-4000-8000-0000000000d3";
    static final String SEASON = "22222222-0000-4000-8000-0000000000d3";
    static final UUID COACH_PERSON = UUID.fromString("33333333-0000-4000-8000-0000000000d3");
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 5)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, true)).toList();

    @Inject
    MatchSeed seed;

    @InjectSpy
    JpaMatchEventRepository events;

    @InjectSpy
    JpaMatchRepository matches;

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void aBatchReadsTheMatchOnceAndRewritesNoUnchangedMark() {
        Script s = Script.unique().start(1, 600).shot(1, 590, player(1), 2, true);
        s.voidOf(1, 580, s.last()).shot(1, 570, player(2), 3, true);
        List<RecordedEvent> script = s.events();
        UUID match = seededMatch(script.subList(0, 3));

        post(match, script.subList(3, 4));

        verify(events, times(1)).findByMatch(any());
        verify(matches, never()).query(anyString(), any(), any());
        verify(events, never()).update(contains("voided_by"), any());
        verify(events, never()).batch(contains("voided_by"), any());
        assertThat(voidedBy(match)).containsExactly(Map.entry(script.get(1).id().toString(),
                script.get(2).id().toString()));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void anEarlierVoidOfTheSameEventMovesOnlyThatMark() {
        Script s = Script.unique().start(1, 600).shot(1, 590, player(1), 2, true);
        EventId shot = s.last();
        s.voidOf(1, 580, shot).voidOf(1, 585, shot);
        List<RecordedEvent> script = s.events();
        UUID match = seededMatch(script.subList(0, 3));

        post(match, script.subList(3, 4));

        verify(events, never()).update(contains("voided_by"), any());
        verify(events, times(1)).batch(contains("voided_by"), argThat(rows -> rows.size() == 1));
        assertThat(voidedBy(match)).containsExactly(Map.entry(shot.toString(), script.get(3).id().toString()));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void aTargetArrivingAfterItsVoidIsMarkedByABatchWithoutAVoid() {
        Script s = Script.unique().start(1, 600).shot(1, 590, player(1), 2, true);
        s.voidOf(1, 580, s.last());
        List<RecordedEvent> script = s.events();
        UUID match = seededMatch(List.of(script.get(0), script.get(2)));

        post(match, script.subList(1, 2));

        verify(events, times(1)).batch(contains("voided_by"), argThat(rows -> rows.size() == 1));
        assertThat(voidedBy(match)).containsExactly(Map.entry(script.get(1).id().toString(),
                script.get(2).id().toString()));
    }

    private UUID seededMatch(List<RecordedEvent> stored) {
        UUID match = seed.match(A, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-03T09:00:00Z"), ROSTER);
        seed.events(A, match, COACH_PERSON, stored);
        clearInvocations(events, matches);
        return match;
    }

    private static void post(UUID match, List<RecordedEvent> batch) {
        given().urlEncodingEnabled(false).header("X-Tenant-Id", A).contentType(ContentType.JSON)
                .body(EventBatches.batch(batch)).post("/api/game/matches/" + match + "/events:batch")
                .then().statusCode(200);
    }

    /** Event id to the id of the VOID that voided it, as the feed reports it. */
    private static Map<String, String> voidedBy(UUID match) {
        List<Map<String, Object>> feed = given().header("X-Tenant-Id", A)
                .get("/api/game/matches/" + match + "/events?after=0&limit=50")
                .then().statusCode(200).extract().jsonPath().getList("events");
        Map<String, String> voided = new HashMap<>();
        for (Map<String, Object> stored : feed) {
            Object by = stored.get("voidedByEventId");
            if (by != null) {
                voided.put((String) ((Map<?, ?>) stored.get("event")).get("id"), (String) by);
            }
        }
        return voided;
    }
}
