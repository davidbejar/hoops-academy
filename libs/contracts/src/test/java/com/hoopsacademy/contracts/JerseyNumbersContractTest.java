package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.atlassian.oai.validator.model.SimpleResponse;
import com.atlassian.oai.validator.report.ValidationReport;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import java.lang.module.ModuleDescriptor;
import java.util.Map;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Core 3.5.0 (WP96, decision 70): a player's preferred jersey number, the rule that numbered a new assignment
 * ({@code jerseySource}) and the numbers taken on a team.
 */
class JerseyNumbersContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parseFullyResolved("core");
    private static final String TENANT = "0190b6a0-0000-7000-8000-0000000000aa";
    private static final String PLAYER = "/api/core/players/0190b6a0-0000-7000-8000-000000000001";
    private static final String TEAM = "/api/core/teams/0190b6a0-0000-7000-8000-000000000002";
    private static final String PLAYER_REF = """
            {"id": "0190b6a0-0000-7000-8000-000000000001", "displayName": "Uma Test"}""";

    private static OpenApiInteractionValidator strict;

    @BeforeAll
    static void strictValidator() {
        strict = OpenApiInteractionValidator.createForSpecificationUrl(ContractFiles.openApi("core").toUri().toString())
                .build();
    }

    @SuppressWarnings("rawtypes")
    private static Map<String, Schema> schemas() {
        return OpenApiSpecs.parse("core").getOpenAPI().getComponents().getSchemas();
    }

    @Test
    void coreIsAtLeast350() {
        assertThat(ModuleDescriptor.Version.parse(CORE.getInfo().getVersion()))
                .isGreaterThanOrEqualTo(ModuleDescriptor.Version.parse("3.5.0"));
    }

    @Test
    void aPlayerCarriesAnOptionalPreferredNumber() {
        Schema<?> preferred = (Schema<?>) schemas().get("Player").getProperties().get("preferredJerseyNumber");

        assertThat(preferred).isNotNull();
        assertThat(preferred.getNullable()).isTrue();
        assertThat(schemas().get("Player").getRequired()).doesNotContain("preferredJerseyNumber");
    }

    @Test
    void thePreferenceIsWrittenWithAPatchThatCanClearIt() {
        Operation update = CORE.getPaths().get("/api/core/players/{playerId}").getPatch();

        assertThat(update.getOperationId()).isEqualTo("updatePlayer");
        assertThat(update.getTags()).containsExactly("Players");
        assertThat(update.getDescription()).contains("Authz: ADMIN; COACH; PARENT (linked); PLAYER (self)");
        assertThat(update.getResponses()).containsKeys("200", "400", "401", "403", "404");
        Schema<?> request = schemas().get("UpdatePlayerRequest");
        assertThat(request.getProperties()).containsOnlyKeys("preferredJerseyNumber", "clear");
        assertThat(request.getMinProperties()).isEqualTo(1);

        assertThat(patch(PLAYER, "{\"preferredJerseyNumber\": \"00\"}").hasErrors()).isFalse();
        assertThat(patch(PLAYER, "{\"clear\": [\"preferredJerseyNumber\"]}").hasErrors()).isFalse();
        assertThat(patch(PLAYER, "{\"preferredJerseyNumber\": \"100\"}").hasErrors()).as("two digits").isTrue();
        assertThat(patch(PLAYER, "{\"preferredJerseyNumber\": \"7a\"}").hasErrors()).as("digits only").isTrue();
        assertThat(patch(PLAYER, "{}").hasErrors()).isTrue();
    }

    @Test
    void anAssignmentSaysWhichRuleChoseItsNumber() {
        Operation assign = CORE.getPaths().get("/api/core/teams/{teamId}/players").getPost();
        Schema<?> created = assign.getResponses().get("201").getContent().get("application/json").getSchema();
        Schema<?> assigned = schemas().get("AssignedTeamPlayer");

        assertThat(created.getProperties()).containsKey("jerseySource");
        assertThat(assigned.getRequired()).contains("jerseySource");
        assertThat(schemas().get("JerseySource").getEnum()).map(String::valueOf)
                .containsExactly("REQUESTED", "PREFERRED", "PREVIOUS", "NONE");
        assertThat(assign.getDescription()).contains("jerseySource", "PREFERRED", "PREVIOUS");

        String body = """
                {"player": %s, "teamId": "0190b6a0-0000-7000-8000-000000000002", "jerseyNumber": "7",
                 "joinedOn": "2026-11-10", "playUpLevels": 0, "playerStatus": "ACTIVE", "jerseySource": "PREFERRED"}"""
                .formatted(PLAYER_REF);
        assertThat(strict.validateResponse(TEAM + "/players", Request.Method.POST,
                SimpleResponse.Builder.status(201).withContentType("application/json").withBody(body).build())
                .hasErrors()).isFalse();
    }

    @Test
    void theTakenNumbersOfATeamNameTheirPlayers() {
        Operation list = CORE.getPaths().get("/api/core/teams/{teamId}/jersey-numbers").getGet();

        assertThat(list.getOperationId()).isEqualTo("listTeamJerseyNumbers");
        assertThat(list.getTags()).containsExactly("Teams");
        assertThat(list.getDescription()).contains("Authz: any member");
        assertThat(list.getResponses()).containsKeys("200", "400", "401", "403", "404");
        assertThat(schemas().get("TakenJerseyNumber").getRequired())
                .containsExactlyInAnyOrder("jerseyNumber", "player");

        String body = "[{\"jerseyNumber\": \"0\", \"player\": %s}, {\"jerseyNumber\": \"00\", \"player\": %s}]"
                .formatted(PLAYER_REF, PLAYER_REF);
        assertThat(strict.validateResponse(TEAM + "/jersey-numbers", Request.Method.GET,
                SimpleResponse.Builder.ok().withContentType("application/json").withBody(body).build())
                .hasErrors()).isFalse();
    }

    private static ValidationReport patch(String path, String body) {
        return strict.validateRequest(SimpleRequest.Builder.patch(path).withContentType("application/json")
                .withHeader("X-Tenant-Id", TENANT).withAuthorization("Bearer test").withBody(body).build());
    }
}
