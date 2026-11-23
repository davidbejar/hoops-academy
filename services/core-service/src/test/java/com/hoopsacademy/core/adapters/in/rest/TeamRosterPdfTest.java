package com.hoopsacademy.core.adapters.in.rest;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.startsWith;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.client.ResponseDefinitionBuilder;
import com.github.tomakehurst.wiremock.http.Fault;
import com.github.tomakehurst.wiremock.verification.LoggedRequest;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.adapters.in.rest.TeamRosterExportTest.Relation;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.LogCapture;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * WP116 (decision 89, ADR-0048 amendment, ADR-0051 §3): {@code Accept: application/pdf} on the roster export gives
 * the printable sheet. Core authorizes and gathers the roster as for the CSV, sends it to pdf-service (stubbed here,
 * the body validated against {@code pdf.yaml}) with its own service token, and returns the PDF; the same audit row
 * with {@code format} {@code pdf}. pdf-service down, slow or refusing: 503 {@code UPSTREAM_UNAVAILABLE}, nothing
 * audited, nothing of the roster logged.
 */
@QuarkusTest
@CoreTestResources
@TestSecurity(user = TenantUser.SUBJECT)
class TeamRosterPdfTest {

    private static final String RENDER = "/pdf/internal/pdf/team-roster";
    private static final String PDF = "application/pdf";
    private static final byte[] SHEET = "%PDF-1.7\n% roster sheet\n".getBytes(StandardCharsets.US_ASCII);
    private static final ObjectMapper JSON = new ObjectMapper();
    private static final OpenApiInteractionValidator PDF_CONTRACT = OpenApiInteractionValidator
            .createForSpecificationUrl("/openapi/pdf.yaml").build();

    @InjectWireMock
    WireMockServer peers;

    private String tenant;
    private UUID lions;
    private UUID coach;
    private UUID uma;

    @BeforeEach
    void aTeamWithPlayersGuardiansAndStaff() {
        KeycloakStubs.installDefaults(peers);
        pdfServiceAnswers(aResponse().withStatus(200).withHeader("Content-Type", PDF)
                .withHeader("Content-Disposition", "attachment; filename=\"from-pdf-service.pdf\"").withBody(SHEET));
        tenant = Members.newTenant();
        UUID season = RosterDb.currentSeason(tenant);
        Map<String, UUID> categories = RosterDb.defaultCategories(tenant);
        lions = RosterDb.team(tenant, season, "U12 Lions", categories.get("U12"), "MIXED");
        coach = CoreDb.person(tenant, "Cora", "Coach", "cora@example.com", TenantRole.COACH);
        UUID assistant = CoreDb.person(tenant, "Ana", "Assist", null, TenantRole.ASSISTANT_COACH);
        RosterDb.staff(tenant, lions, coach, "COACH");
        RosterDb.staff(tenant, lions, assistant, "ASSISTANT_COACH");
        uma = RosterDb.player(tenant, "Uma", "Ant", LocalDate.of(RosterDb.YEAR - 11, 6, 15), "FEMALE");
        UUID ben = RosterDb.player(tenant, "Ben", "Bee", LocalDate.of(RosterDb.YEAR - 11, 1, 2), "MALE");
        UUID gina = CoreDb.person(tenant, "Gina", "Ant", "gina@example.com", TenantRole.PARENT);
        UUID gus = CoreDb.person(tenant, "Gus", "Ant", null, TenantRole.PARENT);
        CoreDb.guardianLink(tenant, gina, uma);
        CoreDb.guardianLink(tenant, gus, uma);
        RosterDb.assignment(tenant, lions, uma, "7");
        UUID invalid = RosterDb.assignment(tenant, lions, ben, null);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.team_player set invalidated_at = now(), "
                + "invalid_reason = 'CATEGORY_TOO_LOW' where id = ?", invalid));
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void anAdminGetsThePrintableRosterNamedAsTheCsv() {
        Response response = print(lions, null);

        response.then().statusCode(200).contentType(PDF).header("Cache-Control", "no-store")
                .header("Content-Disposition", "attachment; filename=\"hoops-" + CoreDb.tenantSlug(tenant) + "-roster-u12-lions-"
                        + RosterDb.TODAY.format(DateTimeFormatter.BASIC_ISO_DATE) + ".pdf\"");
        assertThat(response.asByteArray()).isEqualTo(SHEET);
    }

    @Test
    void coreSendsTheRosterInThePdfContractWithItsServiceToken() throws Exception {
        print(lions, "es-ES, en;q=0.5").then().statusCode(200);

        LoggedRequest sent = single();
        assertThat(sent.getHeader("Authorization")).isEqualTo("Bearer test-service-token");
        assertThat(sent.getHeader("Content-Type")).startsWith("application/json");
        assertThat(PDF_CONTRACT.validateRequest(SimpleRequest.Builder.post("/internal/pdf/team-roster")
                .withContentType("application/json").withAuthorization(sent.getHeader("Authorization"))
                .withBody(sent.getBodyAsString()).build()).getMessages()).isEmpty();
        JsonNode body = JSON.readTree(sent.getBodyAsString());
        assertThat(body.get("locale").asText()).isEqualTo("es");
        assertThat(body.get("academy").get("name").asText()).isEqualTo(
                CoreDb.tenantName(tenant));
        assertThat(body.get("academy").get("timeZone").asText()).isEqualTo(
                RosterDb.text(tenant, "select timezone from core.tenant where id = ?::uuid", tenant));
        assertThat(body.get("team").get("name").asText()).isEqualTo("U12 Lions");
        assertThat(body.get("team").get("season").asText()).isEqualTo(
                RosterDb.text(tenant, "select s.name from core.season s join core.team t on t.season_id = s.id "
                        + "where t.id = ?::uuid", lions.toString()));
        assertThat(body.get("team").get("category").asText()).isNotBlank();
        assertThat(Stream.of(0, 1).map(i -> body.get("players").get(i).get("givenName").asText()))
                .containsExactly("Uma", "Ben");
        assertThat(Stream.of(0, 1).map(i -> body.get("players").get(0).get("guardians").get(i).get("givenName")
                .asText())).containsExactly("Gina", "Gus");
        assertThat(body.get("players").get(0).get("jerseyNumber").asText()).isEqualTo("7");
        assertThat(body.get("players").get(0).get("eligibility").asText()).isEqualTo("ELIGIBLE");
        assertThat(body.get("players").get(0).get("guardians").get(0).get("email").asText())
                .isEqualTo("gina@example.com");
        assertThat(body.get("players").get(1).get("eligibility").asText()).isEqualTo("INELIGIBLE");
        assertThat(body.get("staff").findValuesAsText("role")).containsExactly("COACH", "ASSISTANT_COACH");
        assertThat(body.get("staff").get(0).get("email").asText()).isEqualTo("cora@example.com");
    }

    @ParameterizedTest
    @CsvSource(nullValues = "none", value = {"none, en", "id, id", "es, es", "fr-FR, en", "'de, id;q=0.4', id"})
    void theSheetIsInTheCallersLanguage(String acceptLanguage, String locale) throws Exception {
        print(lions, acceptLanguage).then().statusCode(200);

        assertThat(JSON.readTree(single().getBodyAsString()).get("locale").asText()).isEqualTo(locale);
    }

    @Test
    void theCsvStaysTheAnswerToAnyOtherAccept() {
        for (String accept : List.of("*/*", "text/csv", "text/csv, application/pdf;q=0.5")) {
            request(null).accept(accept).get(path(lions)).then().statusCode(200).contentType(startsWith("text/csv"));
        }
        request(null).accept("application/pdf, text/csv;q=0.5").get(path(lions)).then().statusCode(200)
                .contentType(PDF);
        assertThat(peers.findAll(postRequestedFor(urlEqualTo(RENDER)))).hasSize(1);
    }

    @Test
    void everyPrintIsAuditedWithTheRowCountAndTheFormatOnly() throws Exception {
        print(lions, null).then().statusCode(200);

        Map<String, String> row = CoreDb.auditRow(tenant, "team.roster_exported");
        assertThat(row.get("targetType")).isEqualTo("team");
        assertThat(row.get("targetId")).isEqualTo(lions.toString());
        assertThat(JSON.readTree(row.get("metadata")))
                .isEqualTo(JSON.readTree("{\"rows\": 4, \"format\": \"pdf\"}"));
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.adapters.in.rest.TeamRosterExportTest#callers")
    void roleMatrix(Set<TenantRole> roles, Relation relation, int expected) {
        Members.signInAs(tenant, coach, roles, relation == Relation.STAFF ? Set.of(lions) : Set.of(),
                relation == Relation.FORMER ? Set.of(lions) : Set.of());

        print(lions, null).then().statusCode(expected);

        assertThat(peers.findAll(postRequestedFor(urlEqualTo(RENDER)))).hasSize(expected == 200 ? 1 : 0);
        assertThat(audited()).isEqualTo(expected == 200 ? 1 : 0);
    }

    @Test
    void aNonMemberGetsNotFoundAndNothingIsRendered() {
        Members.signIn(Members.newTenant(), TenantRole.ADMIN, TenantRole.COACH);

        print(lions, null).then().statusCode(404);
        assertThat(peers.findAll(postRequestedFor(urlEqualTo(RENDER)))).isEmpty();
    }

    @Test
    void aPlayerWithMoreGuardiansThanTheSheetHoldsIsTooLargeAndNothingIsSent() {
        for (int i = 3; i <= 5; i++) {
            CoreDb.guardianLink(tenant, CoreDb.person(tenant, "G" + i, "Ant", null, TenantRole.PARENT), uma);
        }

        print(lions, null).then().statusCode(422).body("code", equalTo("EXPORT_TOO_LARGE"));
        assertThat(peers.findAll(postRequestedFor(urlEqualTo(RENDER)))).isEmpty();
        assertThat(audited()).isZero();
        request(null).get(path(lions)).then().statusCode(200).contentType(startsWith("text/csv"));
    }

    static Stream<Arguments> failures() {
        return Stream.of(
                Arguments.of("500", aResponse().withStatus(500).withHeader("Content-Type", "application/problem+json")
                        .withBody("{\"status\":500,\"code\":\"INTERNAL_ERROR\"}")),
                Arguments.of("503 keys", aResponse().withStatus(503)
                        .withHeader("Content-Type", "application/problem+json")
                        .withBody("{\"status\":503,\"code\":\"AUTH_UNAVAILABLE\"}")),
                Arguments.of("401 audience", aResponse().withStatus(401)),
                Arguments.of("400 mapping", aResponse().withStatus(400)
                        .withHeader("Content-Type", "application/problem+json")
                        .withBody("{\"status\":400,\"violations\":[{\"field\":\"players[0].givenName\"}]}")),
                Arguments.of("connection reset", aResponse().withFault(Fault.CONNECTION_RESET_BY_PEER)),
                Arguments.of("slower than the read time-out", aResponse().withStatus(200)
                        .withHeader("Content-Type", PDF).withBody(SHEET).withFixedDelay(3_000)));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("failures")
    void whenPdfServiceCannotRenderTheAnswerIsA503ThatAuditsAndLogsNothingOfTheRoster(String failure,
            ResponseDefinitionBuilder answer) {
        pdfServiceAnswers(answer);

        try (LogCapture logs = LogCapture.start()) {
            print(lions, null).then().statusCode(503).contentType("application/problem+json")
                    .body("code", equalTo("UPSTREAM_UNAVAILABLE"));

            assertThat(logs.containing("Gina")).isEmpty();
            assertThat(logs.containing("gina@example.com")).isEmpty();
            assertThat(logs.containing("U12 Lions")).isEmpty();
        }
        assertThat(audited()).isZero();
    }

    @Test
    void theContentIsNeverLogged() {
        try (LogCapture logs = LogCapture.start()) {
            print(lions, null).then().statusCode(200);

            assertThat(logs.containing("gina@example.com")).isEmpty();
            assertThat(logs.containing("Gina")).isEmpty();
            assertThat(logs.containing("%PDF")).isEmpty();
        }
    }

    private void pdfServiceAnswers(ResponseDefinitionBuilder answer) {
        peers.stubFor(post(urlEqualTo(RENDER)).willReturn(answer));
    }

    private LoggedRequest single() {
        List<LoggedRequest> sent = peers.findAll(postRequestedFor(urlEqualTo(RENDER)));
        assertThat(sent).hasSize(1);
        return sent.get(0);
    }

    private long audited() {
        return CoreDb.auditActions(tenant).stream().filter("team.roster_exported"::equals).count();
    }

    private Response print(UUID team, String language) {
        return request(language).accept(PDF).get(path(team));
    }

    private RequestSpecification request(String language) {
        RequestSpecification request = given().filter(Contract.CORE).urlEncodingEnabled(false)
                .header("X-Tenant-Id", tenant);
        return language == null ? request : request.header("Accept-Language", language);
    }

    private static String path(UUID team) {
        return "/api/core/teams/" + team + "/roster:export";
    }
}
