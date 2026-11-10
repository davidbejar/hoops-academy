package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.atlassian.oai.validator.report.ValidationReport;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.FieldSource;

/**
 * ADR-0032: an {@code Update*Request} names the properties to set to null in a {@code clear} list (absent or null =
 * unchanged), because generated clients cannot send an explicit null. The list is an enum of exactly the optional,
 * nullable properties of the request, so the strict validator rejects a typo or a required field. Specs that have
 * adopted the convention are listed in {@link #ADOPTED} (athlete WP39, core WP44); game follows in its own work package.
 */
class UpdateRequestClearListContractTest {

    private static final List<String> ADOPTED = List.of(
            "athlete",
            "core",
            "game");
    private static final String TEST_TYPE = "/api/athlete/physical-test-types/0190b6a0-0000-7000-8000-000000000001";
    private static final String SESSION = "/api/athlete/training-sessions/0190b6a0-0000-7000-8000-000000000002";
    private static final String TENANT = "0190b6a0-0000-7000-8000-0000000000aa";
    private static final String TEAM = "/api/core/teams/0190b6a0-0000-7000-8000-000000000003";
    private static final String TEAM_PLAYER = TEAM + "/players/0190b6a0-0000-7000-8000-000000000004";

    private static OpenApiInteractionValidator strictAthleteValidator;

    @BeforeAll
    static void strictValidator() {
        strictAthleteValidator = OpenApiInteractionValidator
                .createForSpecificationUrl(ContractFiles.openApi("athlete").toUri().toString()).build();
    }

    private static Map<String, Schema> updateRequests(String service) {
        Map<String, Schema> schemas = OpenApiSpecs.parse(service).getOpenAPI().getComponents().getSchemas();
        Map<String, Schema> updates = new java.util.TreeMap<>();
        schemas.forEach((name, schema) -> {
            if (name.startsWith("Update") && name.endsWith("Request")) {
                updates.put(name, schema);
            }
        });
        return updates;
    }

    private static List<String> nullableProperties(Schema<?> request) {
        return request.getProperties().entrySet().stream()
                .filter(e -> !"clear".equals(e.getKey()))
                .filter(e -> Boolean.TRUE.equals(e.getValue().getNullable()))
                .map(Map.Entry::getKey)
                .toList();
    }

    @ParameterizedTest
    @FieldSource("ADOPTED")
    void everyUpdateRequestWithNullablePropertiesHasAClearListOfExactlyThoseProperties(String service) {
        Map<String, Schema> updates = updateRequests(service);
        assertThat(updates).as(service + " update requests").isNotEmpty();

        updates.forEach((name, request) -> {
            List<String> nullable = nullableProperties(request);
            Schema<?> clear = (Schema<?>) request.getProperties().get("clear");
            if (nullable.isEmpty()) {
                assertThat(clear).as(name + " has nothing to clear").isNull();
                return;
            }
            assertThat(clear).as(name + ".clear").isNotNull();
            assertThat(clear.getType()).as(name + ".clear type").isEqualTo("array");
            assertThat(clear.getUniqueItems()).as(name + ".clear uniqueItems").isTrue();
            assertThat(clear.getDescription()).as(name + ".clear description").contains("ADR-0032");
            assertThat(clear.getItems().getType()).as(name + ".clear items").isEqualTo("string");
            assertThat(clear.getItems().getEnum()).as(name + ".clear enum").map(String::valueOf)
                    .containsExactlyElementsOf(nullable);
            assertThat(Objects.requireNonNullElse(request.getRequired(), List.<String>of()))
                    .as(name + " required").doesNotContainAnyElementsOf(nullable);
        });
    }

    @Test
    void theAthleteRequestsOfTheBriefCarryTheirClearList() {
        Map<String, Schema> updates = updateRequests("athlete");

        assertThat(updates.keySet()).containsAll(Set.of("UpdateTrainingSessionRequest", "UpdatePlannedAbsenceRequest",
                "UpdateBodyMeasurementRequest", "UpdatePhysicalTestResultRequest", "UpdateInjuryRequest",
                "UpdateTrainingPlanRequest", "UpdatePlanItemRequest", "UpdateTrainingScheduleRequest",
                "UpdatePhysicalTestTypeRequest", "UpdateExerciseRequest"));
        updates.forEach((name, request) -> assertThat(request.getProperties()).as(name).containsKey("clear"));
        assertThat(OpenApiSpecs.parse("athlete").getOpenAPI().getInfo().getVersion()).isEqualTo("3.0.0");
    }

    @Test
    void theStrictValidatorAcceptsAClearListAndRejectsAnUnknownOrRequiredName() {
        assertThat(patchSession("{\"clear\": [\"planId\", \"notes\"]}").hasErrors()).isFalse();
        assertThat(patchSession("{\"location\": \"Court 1\", \"clear\": [\"planId\"]}").hasErrors()).isFalse();
        assertThat(patchSession("{\"clear\": [\"plan\"]}").hasErrors()).as("typo").isTrue();
        assertThat(patchSession("{\"clear\": [\"startsAt\"]}").hasErrors()).as("not clearable").isTrue();
        assertThat(patchSession("{\"clear\": [\"notes\", \"notes\"]}").hasErrors()).as("duplicate").isTrue();
    }

    private static ValidationReport patchSession(String body) {
        Request request = SimpleRequest.Builder.patch(SESSION).withContentType("application/json")
                .withHeader("X-Tenant-Id", TENANT).withAuthorization("Bearer test").withBody(body).build();
        return strictAthleteValidator.validateRequest(request);
    }

    @Test
    void theCoreRequestsOfTheBriefClearExactlyTheirOptionalFields() {
        Map<String, Schema> updates = updateRequests("core");

        assertThat(clearEnum(updates, "UpdateTenantProfileRequest")).containsExactly("contactEmail", "websiteUrl");
        assertThat(clearEnum(updates, "UpdateMemberRequest")).containsExactly("email", "phone", "birthDate", "gender");
        assertThat(clearEnum(updates, "UpdateAgeCategoryRequest")).containsExactly("maxAge");
        assertThat(clearEnum(updates, "UpdateTeamRequest")).containsExactly("alias");
        assertThat(clearEnum(updates, "UpdateTeamPlayerRequest")).containsExactly("jerseyNumber");
        assertThat(clearEnum(updates, "UpdatePlayerRequest")).containsExactly("preferredJerseyNumber");
        for (String nothingToClear : List.of("UpdateTenantAdminRequest", "UpdateTenantRequest", "UpdateMeRequest",
                "UpdateSeasonRequest")) {
            assertThat(updates.get(nothingToClear).getProperties()).as(nothingToClear).doesNotContainKey("clear");
        }
        assertThat(updates.get("UpdateTeamPlayerRequest").getMinProperties()).as("clear alone is a body").isEqualTo(1);
        assertThat(java.lang.module.ModuleDescriptor.Version.parse(
                OpenApiSpecs.parse("core").getOpenAPI().getInfo().getVersion()))
                .as("core adopted clear in 2.7.0").isGreaterThanOrEqualTo(
                        java.lang.module.ModuleDescriptor.Version.parse("2.7.0"));
    }

    private static List<String> clearEnum(Map<String, Schema> updates, String name) {
        Schema<?> clear = (Schema<?>) updates.get(name).getProperties().get("clear");
        assertThat(clear).as(name + ".clear").isNotNull();
        return clear.getItems().getEnum().stream().map(String::valueOf).toList();
    }

    @Test
    void theStrictCoreValidatorAcceptsAJerseyClearAndRejectsARequiredName() {
        OpenApiInteractionValidator core = OpenApiInteractionValidator
                .createForSpecificationUrl(ContractFiles.openApi("core").toUri().toString()).build();

        assertThat(patch(core, TEAM_PLAYER, "{\"clear\": [\"jerseyNumber\"]}").hasErrors()).isFalse();
        assertThat(patch(core, TEAM_PLAYER, "{\"jerseyNumber\": \"7\"}").hasErrors()).isFalse();
        assertThat(patch(core, TEAM, "{\"name\": \"Lions\", \"clear\": [\"alias\"]}").hasErrors()).isFalse();
        assertThat(patch(core, TEAM, "{\"clear\": [\"name\"]}").hasErrors()).as("not clearable").isTrue();
        assertThat(patch(core, TEAM, "{\"clear\": [\"alias\", \"alias\"]}").hasErrors()).as("duplicate").isTrue();
    }

    private static ValidationReport patch(OpenApiInteractionValidator validator, String path, String body) {
        Request request = SimpleRequest.Builder.patch(path).withContentType("application/json")
                .withHeader("X-Tenant-Id", TENANT).withAuthorization("Bearer test").withBody(body).build();
        return validator.validateRequest(request);
    }

    @Test
    void aCustomTestTypeCodeCanBeChangedLikeOnCreate() {
        Map<String, Schema> schemas = OpenApiSpecs.parse("athlete").getOpenAPI().getComponents().getSchemas();
        Schema<?> code = (Schema<?>) schemas.get("UpdatePhysicalTestTypeRequest").getProperties().get("code");
        Schema<?> createCode = (Schema<?>) schemas.get("PhysicalTestTypeInput").getProperties().get("code");

        assertThat(code).isNotNull();
        assertThat(code.getPattern()).isEqualTo(createCode.getPattern());
        assertThat(code.getNullable()).isNotEqualTo(Boolean.TRUE);
        Operation update = testTypeOperations().getPatch();
        assertThat(update.getResponses()).containsKey("409");
        assertThat(update.getDescription()).contains("409");
        assertThat(patchTestType("{\"code\": \"SHUTTLE_5X10\"}").hasErrors()).isFalse();
        assertThat(patchTestType("{\"code\": \"bad code\"}").hasErrors()).isTrue();
    }

    private static ValidationReport patchTestType(String body) {
        Request request = SimpleRequest.Builder.patch(TEST_TYPE).withContentType("application/json")
                .withHeader("X-Tenant-Id", TENANT).withAuthorization("Bearer test").withBody(body).build();
        return strictAthleteValidator.validateRequest(request);
    }

    @Test
    void aCustomTestTypeCanBeDeletedUnlessResultsReferenceIt() {
        Operation delete = testTypeOperations().getDelete();

        assertThat(delete).isNotNull();
        assertThat(delete.getOperationId()).isEqualTo("deletePhysicalTestType");
        assertThat(delete.getResponses()).containsKeys("204", "404", "409");
        assertThat(delete.getDescription()).contains("Authz: ADMIN").containsIgnoringCase("results");
    }

    private static io.swagger.v3.oas.models.PathItem testTypeOperations() {
        OpenAPI api = OpenApiSpecs.parse("athlete").getOpenAPI();
        return api.getPaths().get("/api/athlete/physical-test-types/{testTypeId}");
    }

    @Test
    void theGameMatchUpdateCanClearOnlyItsVenue() {
        var game = OpenApiSpecs.parse("game").getOpenAPI();
        Schema<?> clear = (Schema<?>) updateRequests("game").get("UpdateMatchRequest").getProperties().get("clear");

        assertThat(game.getInfo().getVersion()).isEqualTo("2.3.0");
        assertThat(clear.getItems().getEnum()).map(String::valueOf).containsExactly("venue");
    }
}
