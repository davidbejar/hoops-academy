package com.hoopsacademy.game.adapters.in.rest;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.verification.LoggedRequest;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import com.hoopsacademy.game.support.LogCapture;
import com.hoopsacademy.game.support.MatchSeed;
import com.hoopsacademy.game.support.PdfServiceStubs;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import io.restassured.response.ValidatableResponse;
import jakarta.inject.Inject;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * {@code GET /api/game/matches/{id}/box-score:pdf} (WP117, decisions 89 and 90): the readers of the box score
 * (authz matrix "View match stats" and "History: statistics of a past match") get the sheet with exactly the player
 * lines they see in {@code getBoxScore}; non-members 404; pdf-service failures 503 {@code UPSTREAM_UNAVAILABLE};
 * no player name in any log line.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
@TestSecurity(user = MatchSheetPdfResourceTest.SUBJECT)
@OidcSecurity(claims = @Claim(key = "sub", value = MatchSheetPdfResourceTest.SUBJECT))
class MatchSheetPdfResourceTest {

    static final String SUBJECT = "sheet-reader";
    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
    static final String TEAM = "11111111-0000-4000-8000-0000000000e1";
    static final String OTHER_TEAM = "11111111-0000-4000-8000-0000000000e2";
    static final String SEASON = "22222222-0000-4000-8000-0000000000e1";
    static final UUID COACH_PERSON = UUID.fromString("33333333-0000-4000-8000-0000000000e1");
    static final PlayerId CHILD = player(1), SELF = player(2), STRANGER = player(9);
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 6)
            .mapToObj(n -> new RosterEntry(player(n), "Sheet Player " + n, new JerseyNumber(String.valueOf(n)), n <= 5))
            .toList();
    static final List<String> EVERYONE = ROSTER.stream().map(RosterEntry::displayName).toList();

    /** A caller: roles and relations, named for the test report. */
    record Caller(String name, Set<TenantRole> roles, Set<UUID> staffTeams, Set<UUID> historicStaffTeams,
            Set<UUID> linked, PlayerId own) {

        AuthzContext in(String tenant) {
            return new AuthzContext(SUBJECT, UUID.nameUUIDFromBytes(name.getBytes()), TenantId.parse(tenant), roles,
                    staffTeams, linked, Optional.ofNullable(own).map(PlayerId::value), Set.of(),
                    Optional.of(ZoneId.of("Asia/Jakarta")), historicStaffTeams);
        }

        @Override
        public String toString() {
            return name;
        }
    }

    static Caller caller(String name, Set<TenantRole> roles, Set<UUID> staff, Set<UUID> linked, PlayerId own) {
        return new Caller(name, roles, staff, Set.of(), linked, own);
    }

    /** The authz matrix rows "View match stats" and "History: statistics of a past match", as getBoxScore applies them. */
    static Stream<Arguments> callers() {
        UUID team = UUID.fromString(TEAM), otherTeam = UUID.fromString(OTHER_TEAM);
        return Stream.of(
                Arguments.of(caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null), EVERYONE),
                Arguments.of(caller("COACH of the team", Set.of(TenantRole.COACH), Set.of(team), Set.of(), null),
                        EVERYONE),
                Arguments.of(caller("ASSISTANT_COACH of the team", Set.of(TenantRole.ASSISTANT_COACH), Set.of(team),
                        Set.of(), null), EVERYONE),
                Arguments.of(new Caller("former COACH of the team (ended season)", Set.of(TenantRole.COACH), Set.of(),
                        Set.of(team), Set.of(), null), EVERYONE),
                Arguments.of(caller("PARENT linked to the child", Set.of(TenantRole.PARENT), Set.of(),
                        Set.of(CHILD.value()), null), List.of("Sheet Player 1")),
                Arguments.of(caller("PLAYER (self)", Set.of(TenantRole.PLAYER), Set.of(), Set.of(), SELF),
                        List.of("Sheet Player 2")),
                Arguments.of(caller("COACH of another team", Set.of(TenantRole.COACH), Set.of(otherTeam), Set.of(),
                        null), List.of()),
                Arguments.of(caller("PARENT without a link to this match", Set.of(TenantRole.PARENT), Set.of(),
                        Set.of(STRANGER.value()), null), List.of()),
                Arguments.of(caller("PLAYER not in the match", Set.of(TenantRole.PLAYER), Set.of(), Set.of(), STRANGER),
                        List.of()),
                Arguments.of(caller("member without role", Set.of(), Set.of(), Set.of(), null), List.of()));
    }

    @InjectCoreWireMock
    WireMockServer wm;

    @Inject
    MatchSeed seed;

    private final ObjectMapper json = new ObjectMapper();

    @BeforeEach
    void pdfServiceAndCoreAnswer() {
        CoreStubs.reset(wm);
        CoreStubs.teamRoster(wm, A, TEAM, SEASON);
        PdfServiceStubs.rendersMatchSheets(wm);
    }

    @AfterEach
    void forgetCallers() {
        TenantUserRegistry.clear();
    }

    /** A finished match: the child (P1) scores 2, the own player (P2) 3, the opponent 2. */
    private UUID finishedMatch(String tenant) {
        UUID match = seed.match(tenant, TEAM, SEASON, MatchStatus.FINISHED, Instant.parse("2026-11-14T09:00:00Z"),
                ROSTER);
        seed.events(tenant, match, COACH_PERSON, Script.unique().start(1, 600).shot(1, 500, CHILD, 2, true)
                .shot(1, 400, SELF, 3, true).opponent(1, 300, 2).end(1, 0).events());
        return match;
    }

    private static ValidatableResponse sheet(String tenant, UUID match, String acceptLanguage) {
        var request = given().filter(Contract.FILTER).header("X-Tenant-Id", tenant);
        if (acceptLanguage != null) {
            request.header("Accept-Language", acceptLanguage);
        }
        return request.get("/api/game/matches/" + match + "/box-score:pdf").then();
    }

    private JsonNode sentSheet() throws Exception {
        List<LoggedRequest> sent = PdfServiceStubs.sentMatchSheets(wm);
        assertThat(sent).hasSize(1);
        assertThat(PdfServiceStubs.againstTheContract(sent.getFirst()).getMessages()).isEmpty();
        return json.readTree(sent.getFirst().getBodyAsString());
    }

    private static List<String> names(JsonNode sheet) {
        return Stream.iterate(0, i -> i < sheet.at("/players").size(), i -> i + 1)
                .map(i -> sheet.at("/players/" + i + "/displayName").asText()).toList();
    }

    @ParameterizedTest(name = "{0} prints {1}")
    @MethodSource("callers")
    void everyMemberGetsTheSheetWithTheLinesTheBoxScoreShowsThem(Caller caller, List<String> lines) throws Exception {
        UUID match = finishedMatch(A);
        TenantUserRegistry.register(caller.in(A));

        byte[] pdf = sheet(A, match, null).statusCode(200).contentType("application/pdf")
                .header("Content-Disposition", "attachment; filename=\"" + PdfServiceStubs.FILE_NAME + "\"")
                .header("Cache-Control", "no-store").extract().asByteArray();

        assertThat(pdf).isEqualTo(PdfServiceStubs.PDF);
        JsonNode sent = sentSheet();
        assertThat(names(sent)).containsExactlyElementsOf(lines);
        List<String> boxScore = given().header("X-Tenant-Id", A).get("/api/game/matches/" + match + "/box-score")
                .then().statusCode(200).extract().jsonPath().getList("players.displayName", String.class);
        assertThat(names(sent)).as("the same lines as getBoxScore").containsExactlyElementsOf(boxScore);
        assertThat(sent.at("/score/team").asInt()).as("team-level figures for every member").isEqualTo(5);
        assertThat(sent.at("/teamTotals/points").asInt()).isEqualTo(5);
    }

    @Test
    void theSheetCarriesTheMatchTheTeamAndTheAcademysZone() throws Exception {
        UUID match = finishedMatch(A);
        TenantUserRegistry.register(caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null).in(A));

        sheet(A, match, null).statusCode(200);

        JsonNode sent = sentSheet();
        assertThat(sent.at("/match/teamName").asText()).as("core's team name").isEqualTo("U14");
        assertThat(sent.at("/match/opponentName").asText()).startsWith("Rivals");
        assertThat(sent.at("/match/status").asText()).isEqualTo("FINISHED");
        assertThat(sent.at("/academy/timeZone").asText()).isEqualTo("Asia/Jakarta");
        assertThat(sent.at("/academy/name").asText()).as("rest source, consumer off: no replica row")
                .isEqualTo("Hoops Academy");
        assertThat(sent.at("/players/0/jerseyNumber").asText()).isEqualTo("1");
        assertThat(sent.at("/players/0/wasStarter").asBoolean()).isTrue();
        assertThat(sent.at("/players/1/stats/fg3Made").asInt()).isEqualTo(1);
    }

    @ParameterizedTest(name = "Accept-Language \"{0}\" -> {1}")
    @CsvSource(nullValues = "NONE", value = {"NONE, en", "'id, en;q=0.8', id", "es-AR, es", "fr, en"})
    void theLabelsFollowAcceptLanguage(String header, String locale) throws Exception {
        UUID match = finishedMatch(A);
        TenantUserRegistry.register(caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null).in(A));

        sheet(A, match, header).statusCode(200);

        assertThat(sentSheet().at("/locale").asText()).isEqualTo(locale);
    }

    @Test
    void aNonMemberAnotherTenantsMatchAndAnUnknownMatchAre404WithoutRendering() {
        UUID inB = finishedMatch(B);
        UUID inA = finishedMatch(A);
        TenantUserRegistry.register(caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null).in(A));

        sheet(B, inA, null).statusCode(404);
        sheet(A, inB, null).statusCode(404);
        sheet(A, UUID.randomUUID(), null).statusCode(404);

        assertThat(PdfServiceStubs.sentMatchSheets(wm)).isEmpty();
    }

    @Test
    void aPdfServiceFailureIs503AndNoNameIsLogged() {
        UUID match = finishedMatch(A);
        TenantUserRegistry.register(caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null).in(A));
        PdfServiceStubs.answersMatchSheets(wm, PdfServiceStubs.problem(422, "TOO_MANY_ROWS"));

        try (LogCapture logs = LogCapture.start()) {
            sheet(A, match, null).statusCode(503).contentType("application/problem+json")
                    .body("code", equalTo("UPSTREAM_UNAVAILABLE"));

            assertThat(logs.containing("Sheet Player")).isEmpty();
        }
    }

    @Test
    void aRenderedSheetLogsNoName() {
        UUID match = finishedMatch(A);
        TenantUserRegistry.register(caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null).in(A));

        try (LogCapture logs = LogCapture.start()) {
            sheet(A, match, "es").statusCode(200);

            assertThat(logs.containing("Sheet Player")).isEmpty();
        }
    }
}
