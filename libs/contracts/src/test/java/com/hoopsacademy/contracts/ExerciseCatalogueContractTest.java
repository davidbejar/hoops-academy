package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleRequest;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.parameters.Parameter;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * The exercise catalogue (WP92, decision 72, ADR-0047, athlete 3.0.0): global exercises (read-only, localised by
 * {@code Accept-Language}) and the academy's own ones; plan items carry the exercise they came from; quick-add takes an
 * exercise or an item of a readable plan as the source of each copy.
 */
class ExerciseCatalogueContractTest {

    private static final String TENANT = "0190b6a0-0000-7000-8000-0000000000aa";
    private static final String PLAN_ITEMS_COPY = "/api/athlete/training-plans/0190b6a0-0000-7000-8000-000000000001/items:copy";
    private static final String UUID_1 = "0190b6a0-0000-7000-8000-000000000011";
    private static final String UUID_2 = "0190b6a0-0000-7000-8000-000000000012";

    private static OpenApiInteractionValidator strictAthleteValidator;

    @BeforeAll
    static void strictValidator() {
        strictAthleteValidator = OpenApiInteractionValidator
                .createForSpecificationUrl(ContractFiles.openApi("athlete").toUri().toString()).build();
    }

    @SuppressWarnings("rawtypes")
    private static Map<String, Schema> schemas() {
        return OpenApiSpecs.parse("athlete").getOpenAPI().getComponents().getSchemas();
    }

    private static Schema<?> property(String schema, String property) {
        return (Schema<?>) schemas().get(schema).getProperties().get(property);
    }

    private static Operation operation(String operationId) {
        return OpenApiSpecs.parseFullyResolved("athlete").getPaths().values().stream()
                .flatMap(item -> item.readOperations().stream())
                .filter(op -> operationId.equals(op.getOperationId()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("athlete has no operation " + operationId));
    }

    private static Parameter parameter(String operationId, String name) {
        return operation(operationId).getParameters().stream().filter(p -> name.equals(p.getName())).findFirst()
                .orElseThrow(() -> new AssertionError(operationId + " has no parameter " + name));
    }

    @Test
    void theCatalogueIsAMajorVersionThatNamesItsDecisionRecord() {
        var info = OpenApiSpecs.parse("athlete").getOpenAPI().getInfo();

        assertThat(info.getVersion()).isEqualTo("3.0.0");
        assertThat(info.getDescription()).contains("ADR-0047", "exerciseId");
    }

    @ParameterizedTest
    @CsvSource({
        "listExercises, Authz: any member",
        "getExercise, Authz: any member",
        "createExercise, Authz: ADMIN; COACH; ASSISTANT_COACH",
        "updateExercise, Authz: ADMIN; COACH; ASSISTANT_COACH",
        "archiveExercise, Authz: ADMIN; COACH; ASSISTANT_COACH",
        "unarchiveExercise, Authz: ADMIN; COACH; ASSISTANT_COACH"
    })
    void everyCatalogueOperationStatesWhoMayCallIt(String operationId, String authz) {
        assertThat(operation(operationId).getDescription()).contains(authz);
        assertThat(operation(operationId).getTags()).containsExactly("Exercises");
    }

    @ParameterizedTest
    @ValueSource(strings = {"updateExercise", "archiveExercise", "unarchiveExercise"})
    void globalExercisesAreReadOnly(String operationId) {
        assertThat(operation(operationId).getResponses()).containsKey("403");
        assertThat(operation(operationId).getDescription()).contains("EXERCISE_IS_GLOBAL");
    }

    @Test
    void theListSearchesByTitleWithinAScopeAndPages() {
        assertThat(parameter("listExercises", "q").getSchema().getMaxLength()).isEqualTo(100);
        assertThat(parameter("listExercises", "scope").getSchema().getEnum()).map(String::valueOf)
                .containsExactly("GLOBAL", "TENANT");
        assertThat(parameter("listExercises", "includeArchived").getSchema().getDefault()).isEqualTo(false);
        assertThat(operation("listExercises").getParameters()).extracting(Parameter::getName)
                .contains("page", "size", "Accept-Language");
        assertThat(operation("getExercise").getParameters()).extracting(Parameter::getName).contains("Accept-Language");
    }

    @Test
    void anExerciseHasTheContentOfAPlanItemAndSaysWhetherItIsGlobalOrArchived() {
        Schema<?> exercise = schemas().get("Exercise");

        assertThat(exercise.getRequired()).contains("id", "title", "global", "archived");
        assertThat(exercise.getProperties()).containsKeys("nameKey", "description", "durationMinutes", "sets",
                "repetitions", "videoUrl");
        assertThat(property("Exercise", "nameKey").getNullable()).isTrue();
        assertThat(schemas().get("ExerciseInput").getRequired()).containsExactly("title");
        assertThat(property("UpdateExerciseRequest", "clear").getItems().getEnum()).map(String::valueOf)
                .containsExactly("description", "durationMinutes", "sets", "repetitions", "videoUrl");
    }

    @ParameterizedTest
    @ValueSource(strings = {"PlanItem", "PlanItemMatch"})
    void planItemsAndSearchMatchesNameTheExerciseTheyCameFrom(String schema) {
        Schema<?> exerciseId = property(schema, "exerciseId");

        assertThat(exerciseId.getFormat()).isEqualTo("uuid");
        assertThat(exerciseId.getNullable()).isTrue();
        assertThat(Objects.requireNonNullElse(schemas().get(schema).getRequired(), List.<String>of()))
                .doesNotContain("exerciseId");
    }

    @Test
    void aClientCannotSetTheExerciseOfAnItemDirectly() {
        assertThat(schemas().get("PlanItemInput").getProperties()).doesNotContainKey("exerciseId");
        assertThat(schemas().get("UpdatePlanItemRequest").getProperties()).doesNotContainKey("exerciseId");
    }

    @Test
    void quickAddTakesAnExerciseOrAPlanItemAsTheSourceOfEachCopy() {
        Schema<?> source = schemas().get("PlanItemSource");

        assertThat(schemas()).doesNotContainKey("PlanItemRef");
        assertThat(source.getProperties()).containsOnlyKeys("exerciseId", "planId", "itemId");
        assertThat(source.getRequired()).isNullOrEmpty();
        assertThat(property("CopyPlanItemsRequest", "items").getItems().get$ref()).endsWith("/PlanItemSource");
    }

    @ParameterizedTest
    @ValueSource(strings = {"copyItemsToPlan", "copyItemsToSession"})
    void quickAddRefusesAnArchivedExercise(String operationId) {
        assertThat(operation(operationId).getResponses()).containsKey("422");
        assertThat(operation(operationId).getDescription()).contains("EXERCISE_ARCHIVED");
    }

    @Test
    void theStrictValidatorAcceptsBothKindsOfSourceInOneRequest() {
        String body = """
                {"items": [{"exerciseId": "%s"}, {"planId": "%s", "itemId": "%s"}]}""".formatted(UUID_1, UUID_1, UUID_2);

        assertThat(copyItems(body).hasErrors()).isFalse();
        assertThat(copyItems("{\"items\": [{\"exercise\": \"" + UUID_1 + "\"}]}").hasErrors()).as("typo").isTrue();
    }

    private static com.atlassian.oai.validator.report.ValidationReport copyItems(String body) {
        Request request = SimpleRequest.Builder.post(PLAN_ITEMS_COPY).withContentType("application/json")
                .withHeader("X-Tenant-Id", TENANT).withAuthorization("Bearer test").withBody(body).build();
        return strictAthleteValidator.validateRequest(request);
    }
}
