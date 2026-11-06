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
 * adopted the convention are listed in {@link #ADOPTED}; core and game follow in later work packages.
 */
class UpdateRequestClearListContractTest {

    private static final List<String> ADOPTED = List.of("athlete");
    private static final String TEST_TYPE = "/api/athlete/physical-test-types/0190b6a0-0000-7000-8000-000000000001";
    private static final String SESSION = "/api/athlete/training-sessions/0190b6a0-0000-7000-8000-000000000002";
    private static final String TENANT = "0190b6a0-0000-7000-8000-0000000000aa";

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
                "UpdatePhysicalTestTypeRequest"));
        updates.forEach((name, request) -> assertThat(request.getProperties()).as(name).containsKey("clear"));
        assertThat(OpenApiSpecs.parse("athlete").getOpenAPI().getInfo().getVersion()).isEqualTo("2.1.0");
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
}
