package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.parameters.Parameter;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Season history (WP80, ADR-0042): former staff read past seasons, nobody writes them (409 {@code SEASON_ENDED}); the
 * historic staff teams travel in the authorization context, the season end in the internal roster.
 */
class SeasonHistoryContractTest {

    @SuppressWarnings("rawtypes")
    private static Map<String, Schema> schemas(String service) {
        return OpenApiSpecs.parse(service).getOpenAPI().getComponents().getSchemas();
    }

    private static Operation operation(String service, String operationId) {
        return OpenApiSpecs.parseFullyResolved(service).getPaths().values().stream()
                .flatMap(item -> item.readOperations().stream())
                .filter(op -> operationId.equals(op.getOperationId()))
                .findFirst()
                .orElseThrow(() -> new AssertionError(service + " has no operation " + operationId));
    }

    @ParameterizedTest
    @ValueSource(strings = {"AuthzContext", "AuthzSummary"})
    void theAuthorizationContextCarriesTheHistoricStaffTeamsApartFromTheCurrentOnes(String name) {
        Schema<?> schema = schemas("core").get(name);
        Schema<?> historic = (Schema<?>) schema.getProperties().get("historicStaffTeamIds");

        assertThat(historic).as(name + ".historicStaffTeamIds").isNotNull();
        assertThat(historic.getType()).isEqualTo("array");
        assertThat(historic.getItems().getFormat()).isEqualTo("uuid");
        assertThat(schema.getRequired()).contains("historicStaffTeamIds", "staffTeamIds");
        assertThat(historic.getDescription()).contains("ended", "ADR-0042");
    }

    @Test
    void theInternalTeamRosterCarriesItsSeasonEnd() {
        Schema<?> roster = schemas("core").get("TeamRoster");
        Schema<?> end = (Schema<?>) roster.getProperties().get("seasonEndDate");

        assertThat(end).isNotNull();
        assertThat(end.getFormat()).isEqualTo("date");
        assertThat(roster.getRequired()).contains("seasonEndDate");
    }

    @Test
    void aTeamSaysWhetherItsSeasonHasEnded() {
        Schema<?> team = schemas("core").get("Team");

        assertThat(((Schema<?>) team.getProperties().get("seasonEnded")).getType()).isEqualTo("boolean");
        assertThat(team.getRequired()).contains("seasonEnded");
    }

    @Test
    void listTeamsIncludesEndedSeasonsOnlyWhenAsked() {
        Parameter includeEnded = operation("core", "listTeams").getParameters().stream()
                .filter(p -> "includeEnded".equals(p.getName())).findFirst().orElseThrow();

        assertThat(includeEnded.getIn()).isEqualTo("query");
        assertThat(includeEnded.getSchema().getType()).isEqualTo("boolean");
        assertThat(includeEnded.getSchema().getDefault()).isEqualTo(false);
    }

    @ParameterizedTest
    @CsvSource({
        "core, updateTeam", "core, putTeamStaffMember", "core, removeTeamStaffMember", "core, assignPlayerToTeam",
        "core, updateTeamPlayer", "core, unassignPlayerFromTeam",
        "game, createMatch", "game, updateMatch", "game, startMatch", "game, finishMatch", "game, cancelMatch",
        "game, replaceMatchRoster",
        "athlete, createTrainingSchedule", "athlete, updateTrainingSchedule", "athlete, deleteTrainingSchedule",
        "athlete, createTrainingSession", "athlete, updateTrainingSession", "athlete, cancelTrainingSession",
        "athlete, copyItemsToSession", "athlete, recordSessionAttendance", "athlete, createPlanAssignment",
        "athlete, deletePlanAssignment", "athlete, recordPlanCompletion"
    })
    void everyWriteOnAHistoricTeamDeclaresTheSeasonEndedConflict(String service, String operationId) {
        Operation op = operation(service, operationId);

        assertThat(op.getResponses()).as(operationId).containsKey("409");
        assertThat(op.getDescription()).as(operationId).contains("SEASON_ENDED");
    }

    @Test
    void anEventRecordedAfterTheSeasonIsRejectedWithItsOwnReason() {
        List<String> reasons = schemas("game").get("MatchEventRejectionReason").getEnum().stream()
                .map(String::valueOf).toList();

        assertThat(reasons).contains("SEASON_ENDED");
    }

    @ParameterizedTest
    @CsvSource({"core, 3.2.0", "game, 2.3.0", "athlete, 2.4.0"})
    void theContractsCarryTheirSeasonHistoryVersion(String service, String version) {
        assertThat(java.lang.module.ModuleDescriptor.Version.parse(
                OpenApiSpecs.parse(service).getOpenAPI().getInfo().getVersion()))
                .isGreaterThanOrEqualTo(java.lang.module.ModuleDescriptor.Version.parse(version));
        assertThat(OpenApiSpecs.parse(service).getOpenAPI().getInfo().getDescription()).contains("SEASON_ENDED",
                "ADR-0042");
    }
}
