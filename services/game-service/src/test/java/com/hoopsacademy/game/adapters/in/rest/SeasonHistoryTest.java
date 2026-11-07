package com.hoopsacademy.game.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.adapters.out.client.RestRosterPort;
import com.hoopsacademy.game.application.TeamRoster;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreAnswers;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.EventBatches;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import jakarta.inject.Inject;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Season history in game (WP80, ADR-0042): matches of a team whose season has ended are read-only; ADMIN and the
 * team's former staff still see every player's statistics; events recorded during the season still sync.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class SeasonHistoryTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String PAST_TEAM = "11111111-0000-4000-8000-000000000081";
    static final String OTHER_TEAM = "11111111-0000-4000-8000-000000000082";
    static final String SEASON = "22222222-0000-4000-8000-000000000081";
    static final String P1_ID = "99999999-0000-4000-8000-000000000081";
    static final PlayerId P1 = PlayerId.of(UUID.fromString(P1_ID));
    /** The day the events of {@link Script} are recorded on (UTC: the callers below have no zone). */
    static final LocalDate MATCH_DAY = LocalDate.ofInstant(Script.BASE, ZoneOffset.UTC);
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 3)
            .mapToObj(n -> new RosterEntry(PlayerId.of(UUID.fromString("99999999-0000-4000-8000-00000000008" + n)),
                    "Player " + n, null, true)).toList();

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RestRosterPort rosterPort;

    @Inject
    MatchSeed seed;

    @BeforeEach
    void theSeasonOfThePastTeamEndedTheDayBeforeTheMatchDay() {
        seasonEndsOn(MATCH_DAY.minusDays(1));
        CoreStubs.teamRoster(core, A, OTHER_TEAM, SEASON);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void anAdminCannotScheduleOrChangeAMatchOfAnEndedSeason() {
        seasonEnded(request().body(newMatch(PAST_TEAM)).post("/api/game/matches").then());
        UUID scheduled = match(MatchStatus.SCHEDULED);
        seasonEnded(request().body("{\"venue\":\"Gym 2\"}").patch(matchPath(scheduled)).then());
        seasonEnded(request().post(matchPath(scheduled) + "/start").then());
        seasonEnded(request().body("{\"reason\":\"rain\"}").post(matchPath(scheduled) + "/cancel").then());
        seasonEnded(request().body("{\"entries\":[{\"playerId\":\"" + P1_ID + "\",\"isStarter\":true}]}")
                .put(matchPath(scheduled) + "/roster").then());
        seasonEnded(request().post(matchPath(match(MatchStatus.LIVE)) + "/finish").then());

        request().get(matchPath(scheduled)).then().statusCode(200).body("status", equalTo("SCHEDULED"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = OTHER_TEAM, historicStaffTeams = PAST_TEAM)
    void theFormerCoachGetsTheConflictAndStillSeesEveryPlayersStatistics() {
        UUID live = match(MatchStatus.LIVE);
        seed.events(A, live, UUID.randomUUID(), Script.unique().start(1, 600).shot(1, 500, P1, 2, true).events());

        seasonEnded(request().body("{\"venue\":\"Gym 2\"}").patch(matchPath(live)).then());
        seasonEnded(request().post(matchPath(live) + "/finish").then());
        seasonEnded(request().body(newMatch(PAST_TEAM)).post("/api/game/matches").then());
        request().get(matchPath(live) + "/box-score").then().statusCode(200).body("players", hasSize(3));
        request().get(matchPath(live) + "/events").then().statusCode(200).body("events", hasSize(2));
        request().body(newMatch(OTHER_TEAM)).post("/api/game/matches").then().statusCode(201);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void aCoachNeverOnTheTeamIsForbiddenAsBeforeAndSeesNoPlayerLines() {
        UUID live = match(MatchStatus.LIVE);

        request().body("{\"venue\":\"Gym 2\"}").patch(matchPath(live)).then().statusCode(403);
        request().get(matchPath(live) + "/box-score").then().statusCode(200).body("players", hasSize(0));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void eventsRecordedAfterTheSeasonsLastDayAreRejectedEarlierOnesStillSync() {
        UUID live = match(MatchStatus.LIVE);
        Script late = Script.unique().shot(1, 500, P1, 2, true);
        events(live, late).statusCode(200).body("results.status", contains("REJECTED"))
                .body("results.reason", contains("SEASON_ENDED"));

        seasonEndsOn(MATCH_DAY);
        events(live, Script.unique().shot(1, 500, P1, 2, true)).statusCode(200)
                .body("results.status", contains("ACCEPTED"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, historicStaffTeams = PAST_TEAM)
    void theFormerCoachSyncsWhatTheDeviceRecordedDuringTheSeason() {
        seasonEndsOn(MATCH_DAY);
        UUID live = match(MatchStatus.LIVE);

        events(live, Script.unique().shot(1, 500, P1, 2, true)).statusCode(200)
                .body("results.status", contains("ACCEPTED"));
        seasonEndsOn(MATCH_DAY.minusDays(1));
        events(live, Script.unique().shot(1, 500, P1, 2, true)).statusCode(200)
                .body("results.reason", contains("SEASON_ENDED"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, linkedPlayers = P1_ID)
    void aParentsLateEventIsRejectedToo() {
        events(match(MatchStatus.LIVE), Script.unique().shot(1, 500, P1, 2, true)).statusCode(200)
                .body("results.reason", contains("SEASON_ENDED"));
    }

    private void seasonEndsOn(LocalDate lastDay) {
        CoreStubs.reset(core);
        rosterPort.clearCache();
        CoreAnswers.teamRoster(core, TenantId.parse(A), new TeamRoster(TeamId.of(UUID.fromString(PAST_TEAM)),
                SeasonId.of(UUID.fromString(SEASON)), "Lions", List.of(new TeamRoster.Player(P1, "Ann", "4")),
                lastDay));
        CoreStubs.teamRoster(core, A, OTHER_TEAM, SEASON);
    }

    private UUID match(MatchStatus status) {
        return seed.match(A, PAST_TEAM, SEASON, status, Script.BASE.minusSeconds(3600), ROSTER);
    }

    private ValidatableResponse events(UUID match, Script script) {
        return given().filter(Contract.FILTER).urlEncodingEnabled(false).header("X-Tenant-Id", A)
                .contentType(ContentType.JSON).body(EventBatches.batch(script))
                .post("/api/game/matches/" + match + "/events:batch").then();
    }

    private static void seasonEnded(ValidatableResponse response) {
        response.statusCode(409).contentType("application/problem+json").body("code", equalTo("SEASON_ENDED"));
    }

    private static String matchPath(UUID match) {
        return "/api/game/matches/" + match;
    }

    private static String newMatch(String team) {
        return "{\"teamId\":\"" + team + "\",\"opponentName\":\"Lakers\",\"homeAway\":\"HOME\","
                + "\"scheduledAt\":\"" + Instant.now().plusSeconds(86_400) + "\"}";
    }

    private static RequestSpecification request() {
        return given().filter(Contract.FILTER).header("X-Tenant-Id", A).contentType(ContentType.JSON);
    }
}
