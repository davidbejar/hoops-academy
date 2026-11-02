package com.hoopsacademy.contracts;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.responses.ApiResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Cross-cutting contract rules added by the WP2c consolidation: upstream failures (503 / 502), the enriched authorization
 * context, discriminable match events and the operations that existed only in code before.
 */
class CrossServiceContractTest {

    private static final String PROBLEM_JSON = "application/problem+json";

    private static Map<String, Schema> schemas(String service) {
        return OpenApiSpecs.parse(service).getOpenAPI().getComponents().getSchemas();
    }

    private static List<Operation> operationsUnder(OpenAPI api, String prefix) {
        List<Operation> ops = new ArrayList<>();
        api.getPaths().forEach((path, item) -> {
            if (path.startsWith(prefix)) {
                ops.addAll(item.readOperations());
            }
        });
        return ops;
    }

    private static Operation operation(String service, String operationId) {
        return OpenApiSpecs.parseFullyResolved(service).getPaths().values().stream()
                .flatMap(item -> item.readOperations().stream())
                .filter(op -> operationId.equals(op.getOperationId()))
                .findFirst()
                .orElseThrow(() -> new AssertionError(service + " has no operation " + operationId));
    }

    private static List<String> enumOf(Schema<?> schema) {
        return schema.getEnum().stream().map(String::valueOf).toList();
    }

    /** Properties of a schema including its allOf parts (one level of $ref resolved within the same spec). */
    @SuppressWarnings({"rawtypes", "unchecked"})
    private static Map<String, Schema> flatProperties(Map<String, Schema> all, Schema<?> schema) {
        Map<String, Schema> props = new java.util.LinkedHashMap<>();
        if (schema.get$ref() != null) {
            return flatProperties(all, all.get(schema.get$ref().substring(schema.get$ref().lastIndexOf('/') + 1)));
        }
        Objects.requireNonNullElse(schema.getAllOf(), List.<Schema>of()).forEach(part -> props.putAll(flatProperties(all, part)));
        props.putAll(Objects.requireNonNullElse(schema.getProperties(), Map.of()));
        return props;
    }

    // ------------------------------------------------------------------ upstream failures

    @ParameterizedTest
    @ValueSource(strings = {"game", "athlete"})
    void everyTenantOperationOfAServiceThatCallsCoreDeclares503(String service) {
        // the tenant filter of game/athlete resolves the caller through core's /internal/authz on every /api call
        OpenAPI api = OpenApiSpecs.parseFullyResolved(service);

        assertThat(operationsUnder(api, "/api/" + service + "/")).isNotEmpty().allSatisfy(op -> {
            ApiResponse unavailable = op.getResponses().get("503");
            assertThat(unavailable).as(op.getOperationId() + " 503").isNotNull();
            assertThat(unavailable.getContent()).as(op.getOperationId() + " 503 Problem").containsKey(PROBLEM_JSON);
        });
    }

    @Test
    void serviceUnavailableAndUpstreamIdentityProviderAreSharedResponses() {
        var responses = OpenApiSpecs.parse("common").getOpenAPI().getComponents().getResponses();

        assertThat(responses).containsKeys("ServiceUnavailable", "UpstreamIdentityProvider");
    }

    @ParameterizedTest
    @ValueSource(strings = {"createTenant", "inviteMember", "addTenantAdmin", "updateTenantAdmin",
            "issueTenantAdminTemporaryPassword", "updateMember", "issueMemberTemporaryPassword", "createPlayer",
            "approveApprovalRequest"})
    void keycloakBackedOperationsDeclare502(String operationId) {
        ApiResponse badGateway = operation("core", operationId).getResponses().get("502");

        assertThat(badGateway).isNotNull();
        assertThat(badGateway.getContent()).containsKey(PROBLEM_JSON);
    }

    // ------------------------------------------------------------------ authz context

    @ParameterizedTest
    @ValueSource(strings = {"AuthzContext", "AuthzSummary"})
    void authorizationContextCarriesTimezonePlayerTeamsAndOwnPlayer(String schemaName) {
        Map<String, Schema> core = schemas("core");
        Map<String, Schema> props = flatProperties(core, core.get(schemaName));

        assertThat(props).containsKeys("timezone", "playerTeamIds", "ownPlayerId");
        assertThat(props.get("playerTeamIds").getType()).isEqualTo("array");
        assertThat(core.get(schemaName).getRequired()).contains("timezone", "playerTeamIds");
    }

    // ------------------------------------------------------------------ core

    @Test
    void playerStatusDistinguishesRejectedFromWithdrawn() {
        assertThat(enumOf(schemas("core").get("PlayerStatus"))).contains("REJECTED", "WITHDRAWN");
    }

    @Test
    void rejectingAnApprovalRequestRequiresANote() {
        Schema<?> body = operation("core", "rejectApprovalRequest").getRequestBody().getContent()
                .get("application/json").getSchema();

        assertThat(body.getRequired()).contains("note");
        assertThat(body.getProperties().get("note").getMinLength()).isEqualTo(1);
    }

    @Test
    void tenantUsageHistoryListsDailySnapshots() {
        Operation history = operation("core", "getTenantUsageHistory");

        assertThat(history.getParameters()).extracting(p -> p.getName()).contains("tenantId", "from", "to");
        Schema<?> body = history.getResponses().get("200").getContent().get("application/json").getSchema();
        assertThat(body.getProperties()).containsKeys("tenantId", "snapshots");
    }

    // ------------------------------------------------------------------ game

    @Test
    void everyMatchEventVariantFixesItsType() {
        Map<String, Schema> game = schemas("game");
        Map<String, String> mapping = game.get("MatchEvent").getDiscriminator().getMapping();

        mapping.forEach((type, ref) -> {
            Schema<?> variant = game.get(ref.substring(ref.lastIndexOf('/') + 1));
            Schema<?> typeProperty = (Schema<?>) variant.getAllOf().stream()
                    .map(part -> ((Schema<?>) part).getProperties())
                    .filter(Objects::nonNull)
                    .map(p -> p.get("type"))
                    .filter(Objects::nonNull)
                    .findFirst()
                    .orElseThrow(() -> new AssertionError(ref + " has no fixed type"));
            assertThat(enumOf(typeProperty)).as(ref).containsExactly(type);
        });
    }

    @Test
    void rejectionReasonsNameReusedIdsAndNotStartedMatches() {
        assertThat(enumOf(schemas("game").get("MatchEventRejectionReason")))
                .contains("EVENT_ID_REUSED", "MATCH_NOT_STARTED", "CLIENT_SEQ_CONFLICT");
    }

    @Test
    void statLineCountsTechnicalAndUnsportsmanlikeFoulsAndBoxScoreHasNoSourcelessOpponentFouls() {
        Map<String, Schema> game = schemas("game");

        assertThat(game.get("StatLine").getProperties()).containsKeys("technicalFouls", "unsportsmanlikeFouls");
        assertThat(game.get("StatLine").getRequired()).contains("technicalFouls", "unsportsmanlikeFouls");
        assertThat(game.get("BoxScore").getProperties()).doesNotContainKey("opponentFouls");
    }

    // ------------------------------------------------------------------ athlete

    @ParameterizedTest
    @ValueSource(strings = {"getPlayerAvailability", "archiveTrainingPlan", "unarchiveTrainingPlan", "getPlanAssignmentProgress"})
    void athleteOperationsThatExistedOnlyInCodeAreDeclared(String operationId) {
        assertThat(operation("athlete", operationId).getResponses()).containsKey("200");
    }

    @Test
    void availabilityHasTheImplementedShape() {
        Schema<?> availability = schemas("athlete").get("PlayerAvailability");

        assertThat(availability.getRequired()).containsExactlyInAnyOrder("playerId", "available", "injuries");
        assertThat(availability.getProperties()).containsKeys("expectedReturnOn");
    }

    @Test
    void testResultsFlagHowTheBandWasResolvedAndMayLackAnAge() {
        Map<String, Schema> athlete = schemas("athlete");
        Map<String, Schema> result = flatProperties(athlete, athlete.get("PhysicalTestResult"));

        assertThat(enumOf(athlete.get("BandStatus"))).containsExactly("MATCHED", "NO_NORM", "MISSING_PLAYER_DATA");
        assertThat(result).containsKey("bandStatus");
        assertThat(result.get("ageAtMeasurement").getNullable()).isTrue();
    }

    @Test
    void planSummariesExposeTheArchivedFlag() {
        assertThat(schemas("athlete").get("TrainingPlanSummary").getProperties()).containsKey("archived");
    }
}
