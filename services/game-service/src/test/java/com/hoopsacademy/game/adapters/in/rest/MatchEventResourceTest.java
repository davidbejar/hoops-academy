package com.hoopsacademy.game.adapters.in.rest;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.MatchEvent.ReboundKind;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.EventBatches;
import com.hoopsacademy.game.support.EventSchema;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class MatchEventResourceTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
    static final String TEAM = "11111111-0000-4000-8000-000000000071";
    static final String OTHER_TEAM = "11111111-0000-4000-8000-000000000072";
    static final String SEASON = "22222222-0000-4000-8000-000000000071";
    static final String COACH_PERSON = "33333333-0000-4000-8000-000000000071";
    static final String PARENT_PERSON = "33333333-0000-4000-8000-000000000072";
    static final PlayerId P1 = player(1), P2 = player(2), P6 = player(6);
    static final String LINKED = "00000000-0000-4000-8000-000000000001";
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 6)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, n <= 5)).toList();

    @Inject
    MatchSeed seed;

    UUID match(String tenant, MatchStatus status) {
        return seed.match(tenant, TEAM, SEASON, status, Instant.parse("2026-11-01T09:00:00Z"), ROSTER);
    }

    static RequestSpecification asA() {
        return given().filter(Contract.FILTER).header("X-Tenant-Id", A).contentType(ContentType.JSON);
    }

    /** See {@link Contract#BATCH}; ':' is sent unencoded, as the generated clients do. */
    static ValidatableResponse post(UUID match, String body) {
        return given().filter(Contract.BATCH).urlEncodingEnabled(false).header("X-Tenant-Id", A)
                .contentType(ContentType.JSON).body(body).post("/api/game/matches/" + match + "/events:batch").then();
    }

    /** GET of the feed; the body is checked with {@link EventSchema#assertValidFeed} (see {@link Contract#FEED}). */
    static ValidatableResponse feed(String tenant, UUID match, String query) {
        ValidatableResponse response = given().filter(Contract.FEED).header("X-Tenant-Id", tenant)
                .get("/api/game/matches/" + match + "/events" + query).then();
        if (response.extract().statusCode() == 200) {
            EventSchema.assertValidFeed(response.extract().asString());
        }
        return response;
    }

    static List<String> ids(Script script) {
        return script.events().stream().map(e -> e.id().toString()).toList();
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffBatchIsAcceptedInRequestOrderAndProjected() {
        UUID match = match(A, MatchStatus.LIVE);
        Script s = Script.unique().start(1, 600).shot(1, 550, P1, 2, true).opponent(1, 500, 3).assist(1, 550, P2);

        List<Integer> seqs = post(match, EventBatches.batch(s)).statusCode(200)
                .body("results.eventId", contains(ids(s).toArray()))
                .body("results.status", everyItem(equalTo("ACCEPTED")))
                .body("results.reason", everyItem(nullValue()))
                .extract().jsonPath().getList("results.serverSeq", Integer.class);
        assertThat(seqs).isSorted().doesNotHaveDuplicates();
        long last = seqs.get(seqs.size() - 1);

        asA().get("/api/game/matches/" + match + "/box-score").then().statusCode(200)
                .body("score.team", equalTo(2)).body("score.opponent", equalTo(3))
                .body("lastServerSeq", equalTo((int) last))
                .body("players.find { it.playerId == '" + P1 + "' }.stats.points", equalTo(2))
                .body("players.find { it.playerId == '" + P2 + "' }.stats.assists", equalTo(1));
        asA().get("/api/game/matches/" + match).then().statusCode(200)
                .body("score.team", equalTo(2)).body("score.opponent", equalTo(3)).body("lastServerSeq", equalTo((int) last));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ASSISTANT_COACH, staffTeams = TEAM)
    void repostingABatchIsAllDuplicateWithTheOriginalSeqsAndAnIdenticalProjection() {
        UUID match = match(A, MatchStatus.LIVE);
        Script s = Script.unique().start(1, 600).subOut(1, 400, P1).subIn(1, 400, P6).shot(1, 300, P6, 3, true).end(1, 0);
        List<Integer> first = post(match, EventBatches.batch(s)).statusCode(200)
                .extract().jsonPath().getList("results.serverSeq", Integer.class);
        String boxBefore = asA().get("/api/game/matches/" + match + "/box-score").asString();

        post(match, EventBatches.batch(s)).statusCode(200)
                .body("results.status", everyItem(equalTo("DUPLICATE")))
                .body("results.serverSeq", contains(first.toArray()))
                .body("lastServerSeq", equalTo(first.get(first.size() - 1)));

        assertThat(asA().get("/api/game/matches/" + match + "/box-score").asString()).isEqualTo(boxBefore);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, personId = PARENT_PERSON, linkedPlayers = LINKED)
    void parentMayRecordStatsOfTheLinkedPlayerAndVoidOwnEventsOnly() {
        UUID match = match(A, MatchStatus.LIVE);
        Script coach = Script.unique().device("bench").start(1, 600).shot(1, 590, P2, 2, true);
        seed.events(A, match, UUID.fromString(COACH_PERSON), coach.events());
        RecordedEvent coachShot = coach.events().get(1);

        Script parent = Script.unique().device("parent-phone")
                .shot(1, 550, P1, 2, true)              // linked player
                .shot(1, 540, P2, 2, true)              // another player
                .start(2, 600)                          // clock / period event
                .voidOf(1, 530, coachShot.id());        // the coach's event
        parent.voidOf(1, 520, parent.events().get(0).id()); // own event, same batch

        post(match, EventBatches.batch(parent)).statusCode(200)
                .body("results.status", contains("ACCEPTED", "REJECTED", "REJECTED", "REJECTED", "ACCEPTED"))
                .body("results.reason", contains(null, "NOT_AUTHORIZED", "NOT_AUTHORIZED", "NOT_AUTHORIZED", null));

        asA().get("/api/game/matches/" + match + "/box-score").then().statusCode(200)
                .body("score.team", equalTo(2)) // coach's shot stays, the parent's own shot is voided
                .body("players", hasSize(1))
                .body("players[0].playerId", equalTo(P1.toString()))
                .body("players[0].stats.points", equalTo(0));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PLAYER, ownPlayer = LINKED)
    void playerMayRecordNothing() {
        UUID match = match(A, MatchStatus.LIVE);

        post(match, EventBatches.batch(Script.unique().shot(1, 550, P1, 2, true).start(1, 600))).statusCode(200)
                .body("results.reason", everyItem(equalTo("NOT_AUTHORIZED")));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void staffOfAnotherTeamMayRecordNothing() {
        UUID match = match(A, MatchStatus.LIVE);

        post(match, EventBatches.batch(Script.unique().start(1, 600))).statusCode(200)
                .body("results[0].reason", equalTo("NOT_AUTHORIZED"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void invalidEventsAreRejectedOneByOneAndTheRestIsStored() {
        UUID match = match(A, MatchStatus.LIVE);
        Script s = Script.unique().shot(1, 550, P1, 2, true).shot(1, 540, P1, 2, true).shot(1, 530, P1, 2, true);
        ObjectNode valid = EventBatches.json(s.events().get(0));
        ObjectNode noPoints = EventBatches.json(s.events().get(1));
        ((ObjectNode) noPoints.get("payload")).remove("points");
        ObjectNode badId = EventBatches.json(s.events().get(2)).put("id", "nope");

        given().filter(Contract.RESPONSES_ONLY).urlEncodingEnabled(false).header("X-Tenant-Id", A).contentType(ContentType.JSON)
                .body(EventBatches.raw(List.of(valid, noPoints, badId)))
                .post("/api/game/matches/" + match + "/events:batch").then().statusCode(200)
                .body("results.status", contains("ACCEPTED", "REJECTED", "REJECTED"))
                .body("results.reason", contains(null, "SCHEMA_INVALID", "SCHEMA_INVALID"))
                .body("results[1].eventId", equalTo(s.events().get(1).id().toString()))
                .body("results[1].message", containsString("points"))
                .body("results[2].eventId", equalTo("00000000-0000-0000-0000-000000000000"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void cancelledMatchRejectsEveryEvent() {
        UUID match = match(A, MatchStatus.CANCELLED);

        post(match, EventBatches.batch(Script.unique().start(1, 600).shot(1, 500, P1, 2, true))).statusCode(200)
                .body("results.reason", everyItem(equalTo("MATCH_CANCELLED")))
                .body("lastServerSeq", equalTo(0));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void scheduledAndFinishedMatchesAcceptEventsSoOfflineDevicesLoseNothing() {
        for (MatchStatus status : List.of(MatchStatus.SCHEDULED, MatchStatus.FINISHED)) {
            UUID match = match(A, status);
            post(match, EventBatches.batch(Script.unique().start(1, 600))).statusCode(200)
                    .body("results[0].status", equalTo("ACCEPTED"));
        }
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void deviceSequenceReusedByAnotherIdIsAConflictAndSoIsAnIdOfAnotherMatch() {
        UUID match = match(A, MatchStatus.LIVE);
        UUID other = match(A, MatchStatus.LIVE);
        Script first = Script.unique().start(1, 600);
        Script sameDeviceSeq = Script.unique().start(1, 600);
        post(match, EventBatches.batch(first)).statusCode(200).body("results[0].status", equalTo("ACCEPTED"));

        post(match, EventBatches.batch(sameDeviceSeq)).statusCode(200)
                .body("results[0].reason", equalTo("CLIENT_SEQ_CONFLICT"))
                .body("results[0].message", containsString(first.events().get(0).id().toString()));
        post(other, EventBatches.batch(first)).statusCode(200)
                .body("results[0].reason", equalTo("CLIENT_SEQ_CONFLICT"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void wholeRequestErrors() {
        UUID match = match(A, MatchStatus.LIVE);
        Script tooMany = Script.unique();
        IntStream.range(0, 501).forEach(i -> tooMany.note(1, 600, "n" + i));

        for (String body : List.of("{}", "{\"events\":[]}", "{\"events\":{}}", "[1]", EventBatches.batch(tooMany))) {
            given().urlEncodingEnabled(false).header("X-Tenant-Id", A).contentType(ContentType.JSON).body(body)
                    .post("/api/game/matches/" + match + "/events:batch").then().statusCode(400)
                    .contentType("application/problem+json");
        }
        given().urlEncodingEnabled(false).header("X-Tenant-Id", A).contentType(ContentType.JSON).body("{not json")
                .post("/api/game/matches/" + match + "/events:batch").then().statusCode(400);
        post(UUID.randomUUID(), EventBatches.batch(Script.unique().start(1, 600))).statusCode(404);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void anotherTenantsMatchIsNotFoundAndNonMembersGet404() {
        UUID inB = match(B, MatchStatus.LIVE);
        String body = EventBatches.batch(Script.unique().start(1, 600));

        post(inB, body).statusCode(404);
        feed(A, inB, "").statusCode(404);
        given().urlEncodingEnabled(false).header("X-Tenant-Id", B).contentType(ContentType.JSON).body(body)
                .post("/api/game/matches/" + inB + "/events:batch").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM, personId = COACH_PERSON)
    void feedPagesByServerSeqAndShowsVoidsAndRecorder() throws Exception {
        UUID match = match(A, MatchStatus.LIVE);
        Script s = Script.unique().start(1, 600).rebound(1, 500, P1, ReboundKind.OFFENSIVE).shot(1, 490, P1, 2, true);
        s.voidOf(1, 480, s.events().get(1).id()).end(1, 0);
        List<Integer> seqs = post(match, EventBatches.batch(s)).statusCode(200)
                .extract().jsonPath().getList("results.serverSeq", Integer.class);

        feed(A, match, "?after=0&limit=2").statusCode(200)
                .body("events", hasSize(2)).body("hasMore", equalTo(true))
                .body("lastServerSeq", equalTo(seqs.get(4)))
                .body("events.serverSeq", contains(seqs.get(0), seqs.get(1)))
                .body("events[1].event.type", equalTo("REBOUND"))
                .body("events[1].event.payload.kind", equalTo("OFFENSIVE"))
                .body("events[1].voidedByEventId", equalTo(s.events().get(3).id().toString()))
                .body("events[0].voidedByEventId", nullValue())
                .body("events[0].recordedBy.personId", equalTo(COACH_PERSON))
                .body("events[0].recordedBy.displayName", notNullValue())
                .body("events[0].receivedAt", notNullValue());
        String page = feed(A, match, "?after=" + seqs.get(1)).statusCode(200)
                .body("events", hasSize(3)).body("hasMore", equalTo(false))
                .extract().asString();
        for (int i = 0; i < 3; i++) { // the feed returns exactly what was posted
            assertThat(EventBatches.JSON.readTree(page).at("/events/" + i + "/event"))
                    .isEqualTo(EventBatches.JSON.readTree(EventBatches.json(s.events().get(i + 2)).toString()));
        }
        given().header("X-Tenant-Id", A).get("/api/game/matches/" + match + "/events?limit=1001").then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, linkedPlayers = LINKED)
    void parentsAndPlayersMayReadTheFeed() {
        UUID match = match(A, MatchStatus.LIVE);
        seed.events(A, match, UUID.fromString(COACH_PERSON), Script.unique().start(1, 600).events());

        feed(A, match, "").statusCode(200).body("events", hasSize(1));
    }
}
