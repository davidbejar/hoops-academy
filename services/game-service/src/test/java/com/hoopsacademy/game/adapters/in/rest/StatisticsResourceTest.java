package com.hoopsacademy.game.adapters.in.rest;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.response.ValidatableResponse;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Box score and season statistics: visibility per role (authz matrix "View match stats"), contract, isolation. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class StatisticsResourceTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
    static final String TEAM = "11111111-0000-4000-8000-000000000081";
    static final String OTHER_TEAM = "11111111-0000-4000-8000-000000000082";
    static final String SEASON = "22222222-0000-4000-8000-000000000081";
    static final String OTHER_SEASON = "22222222-0000-4000-8000-000000000082";
    /** Season of the box-score matches, kept apart from the season-statistics fixtures. */
    static final String BOX_SEASON = "22222222-0000-4000-8000-000000000083";
    static final String COACH_PERSON = "33333333-0000-4000-8000-000000000081";
    static final PlayerId P1 = player(1), P2 = player(2);
    static final String P1_ID = "00000000-0000-4000-8000-000000000001";
    static final String P2_ID = "00000000-0000-4000-8000-000000000002";
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 6)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, n <= 5)).toList();
    private static boolean seasonSeeded;

    @Inject
    MatchSeed seed;

    @BeforeEach
    void seedSeasonOnce() {
        if (seasonSeeded) {
            return;
        }
        seasonSeeded = true;
        // counted: FINISHED and LIVE matches of SEASON
        played(A, SEASON, MatchStatus.FINISHED, "2026-11-01T10:00:00Z", 10);
        played(A, SEASON, MatchStatus.LIVE, "2026-11-08T10:00:00Z", 3);
        // not counted: scheduled, other season, other tenant
        played(A, SEASON, MatchStatus.SCHEDULED, "2026-11-15T10:00:00Z", 7);
        played(A, OTHER_SEASON, MatchStatus.FINISHED, "2026-10-01T10:00:00Z", 20);
        played(B, SEASON, MatchStatus.FINISHED, "2026-11-01T10:00:00Z", 30);
    }

    /** A match in which P1 scores {@code points} (in twos and a free throw) and the opponent 2. */
    private UUID played(String tenant, String season, MatchStatus status, String at, int points) {
        UUID match = seed.match(tenant, TEAM, season, status, Instant.parse(at), ROSTER);
        Script s = Script.unique().start(1, 600);
        for (int i = 0; i < points / 2; i++) {
            s.shot(1, 500 - i, P1, 2, true);
        }
        if (points % 2 == 1) {
            s.shot(1, 400, P1, 1, true);
        }
        s.assist(1, 300, P1).opponent(1, 200, 2).end(1, 0);
        seed.events(tenant, match, UUID.fromString(COACH_PERSON), s.events());
        return match;
    }

    private UUID liveMatchWithScore() {
        UUID match = seed.match(A, TEAM, BOX_SEASON, MatchStatus.LIVE, Instant.parse("2026-12-01T10:00:00Z"), ROSTER);
        seed.events(A, match, UUID.fromString(COACH_PERSON), Script.unique()
                .start(1, 600).shot(1, 500, P1, 2, true).shot(1, 400, P2, 3, true).opponent(1, 300, 2)
                .subIn(1, 200, P1) // already on court: a warning on P1's line
                .events());
        return match;
    }

    static ValidatableResponse boxScore(UUID match) {
        return given().filter(Contract.FILTER).header("X-Tenant-Id", A).get("/api/game/matches/" + match + "/box-score").then();
    }

    static ValidatableResponse seasonStats(String player, String season) {
        return given().filter(Contract.FILTER).header("X-Tenant-Id", A)
                .get("/api/game/players/" + player + "/season-stats?seasonId=" + season).then();
    }

    // ---------------------------------------------------------------- box score

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void teamStaffSeesEveryLineScoresAndWarnings() {
        UUID match = liveMatchWithScore();

        boxScore(match).statusCode(200)
                .body("matchId", equalTo(match.toString())).body("status", equalTo("LIVE"))
                .body("score.team", equalTo(5)).body("score.opponent", equalTo(2))
                .body("periodScores", hasSize(4)).body("periodScores[0].team", equalTo(5))
                .body("teamTotals.points", equalTo(5)).body("teamTotals.fg3Made", equalTo(1))
                .body("players", hasSize(6))
                .body("players.playerId", contains(ROSTER.stream().map(r -> r.playerId().toString()).toArray()))
                .body("players[0].displayName", equalTo("Player 1")).body("players[0].wasStarter", equalTo(true))
                .body("players[0].stats.points", equalTo(2)).body("players[0].stats.secondsPlayed", equalTo(400))
                .body("players[0].warnings[0].code", equalTo("SUB_IN_PLAYER_ON_COURT"))
                .body("warnings", hasSize(0));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void adminSeesEveryLine() {
        boxScore(liveMatchWithScore()).statusCode(200).body("players", hasSize(6));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, linkedPlayers = P1_ID)
    void parentSeesTheLinkedPlayersLineAndTheTeamTotals() {
        boxScore(liveMatchWithScore()).statusCode(200)
                .body("players.playerId", contains(P1_ID)).body("teamTotals.points", equalTo(5));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PLAYER, ownPlayer = P2_ID)
    void playerSeesOwnLine() {
        boxScore(liveMatchWithScore()).statusCode(200)
                .body("players.playerId", contains(P2_ID)).body("players[0].stats.points", equalTo(3));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void staffOfAnotherTeamSeesScoresButNoPlayerLines() {
        boxScore(liveMatchWithScore()).statusCode(200).body("players", hasSize(0)).body("score.team", equalTo(5));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void matchWithoutEventsHasAZeroBoxScore() {
        UUID match = seed.match(A, TEAM, BOX_SEASON, MatchStatus.SCHEDULED, Instant.parse("2026-12-24T10:00:00Z"), ROSTER);

        boxScore(match).statusCode(200).body("score.team", equalTo(0)).body("lastServerSeq", equalTo(0))
                .body("players", hasSize(6)).body("players[0].stats.points", equalTo(0));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void boxScoreOfAnotherTenantsOrUnknownMatchIs404() {
        UUID inB = seed.match(B, TEAM, BOX_SEASON, MatchStatus.LIVE, Instant.parse("2026-12-01T10:00:00Z"), ROSTER);

        boxScore(inB).statusCode(404);
        boxScore(UUID.randomUUID()).statusCode(404);
    }

    // ---------------------------------------------------------------- season stats

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void seasonStatsAggregateLiveAndFinishedMatchesOfTheSeasonOnly() {
        seasonStats(P1_ID, SEASON).statusCode(200)
                .body("playerId", equalTo(P1_ID)).body("seasonId", equalTo(SEASON))
                .body("gamesPlayed", equalTo(2)).body("gamesStarted", equalTo(2))
                .body("totals.points", equalTo(13)).body("totals.assists", equalTo(2))
                .body("averages.points", equalTo(6.5f)).body("averages.minutesPlayed", equalTo(10.0f))
                .body("matches.status", contains("FINISHED", "LIVE"))
                .body("matches[0].stats.points", equalTo(10));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void adminMaySeeAnyPlayer() {
        seasonStats(P1_ID, SEASON).statusCode(200).body("gamesPlayed", equalTo(2));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ASSISTANT_COACH, staffTeams = TEAM)
    void assistantCoachMaySeeAnyPlayer() {
        seasonStats(P1_ID, SEASON).statusCode(200);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, linkedPlayers = P1_ID)
    void parentSeesLinkedPlayersOnly() {
        seasonStats(P1_ID, SEASON).statusCode(200).body("totals.points", equalTo(13));
        seasonStats(P2_ID, SEASON).statusCode(404).contentType("application/problem+json");
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PLAYER, ownPlayer = P1_ID)
    void playerSeesSelfOnly() {
        seasonStats(P1_ID, SEASON).statusCode(200);
        seasonStats(P2_ID, SEASON).statusCode(404);
    }

    @Test
    @TenantUser(tenant = A)
    void memberWithoutRoleGets404() {
        seasonStats(P1_ID, SEASON).statusCode(404);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void seasonIsRequiredAndUnknownSeasonsAreEmpty() {
        given().header("X-Tenant-Id", A).get("/api/game/players/" + P1_ID + "/season-stats").then().statusCode(400);
        seasonStats(P1_ID, UUID.randomUUID().toString()).statusCode(200)
                .body("gamesPlayed", equalTo(0)).body("matches", hasSize(0)).body("averages.points", equalTo(0.0f));
    }

    @Test
    @TenantUser(tenant = B, roles = TenantRole.ADMIN)
    void otherTenantsSeeOnlyTheirOwnMatches() {
        given().filter(Contract.FILTER).header("X-Tenant-Id", B)
                .get("/api/game/players/" + P1_ID + "/season-stats?seasonId=" + SEASON).then().statusCode(200)
                .body("gamesPlayed", equalTo(1)).body("totals.points", equalTo(30));
        given().header("X-Tenant-Id", A)
                .get("/api/game/players/" + P1_ID + "/season-stats?seasonId=" + SEASON).then().statusCode(404);
    }
}
