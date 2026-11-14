package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.atlassian.oai.validator.model.SimpleResponse;
import com.atlassian.oai.validator.report.ValidationReport;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.parameters.Parameter;
import io.swagger.v3.oas.models.responses.ApiResponse;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Core 3.5.0 (WP96, decisions 67 and 68, ADR-0048): the team roster with guardians and the audit trails are exported
 * by core as CSV files, one {@code :export} operation each, with the filters of the JSON reads, the user's language,
 * a 10,000-row limit (422) and {@code Cache-Control: no-store}.
 */
class ExportsContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parseFullyResolved("core");
    private static final String TENANT = "0190b6a0-0000-7000-8000-0000000000aa";
    private static final String ROSTER = "/api/core/teams/{teamId}/roster:export";
    private static final String AUDIT = "/api/core/audit-events:export";
    private static final String PLATFORM_AUDIT = "/platform/audit-events:export";
    private static final String CSV = "text/csv";

    private static OpenApiInteractionValidator strict;

    @BeforeAll
    static void strictValidator() {
        strict = OpenApiInteractionValidator.createForSpecificationUrl(ContractFiles.openApi("core").toUri().toString())
                .build();
    }

    private static Operation get(String path) {
        return CORE.getPaths().get(path).getGet();
    }

    @ParameterizedTest
    @ValueSource(strings = {ROSTER, AUDIT, PLATFORM_AUDIT})
    void everyExportIsOneCsvFileThatIsNeverCached(String path) {
        Operation export = get(path);
        ApiResponse ok = export.getResponses().get("200");

        assertThat(CORE.getPaths().get(path).readOperations()).as("read-only").hasSize(1);
        assertThat(ok.getContent()).containsOnlyKeys(CSV);
        MediaType csv = ok.getContent().get(CSV);
        assertThat(csv.getSchema().getType()).isEqualTo("string");
        assertThat(csv.getSchema().getFormat()).isEqualTo("binary");
        assertThat(ok.getHeaders()).containsKeys("Content-Disposition", "Cache-Control");
        assertThat(export.getResponses()).containsKeys("400", "401", "403", "404", "422");
        assertThat(export.getDescription()).contains("10,000", "EXPORT_TOO_LARGE", "UTF-8", "ADR-0048");
        assertThat(parameterNames(export)).contains("Accept-Language");
    }

    @Test
    void theRosterExportIsForTheAdminAndTheTeamsCoachAndIsAudited() {
        Operation roster = get(ROSTER);

        assertThat(roster.getOperationId()).isEqualTo("exportTeamRoster");
        assertThat(roster.getTags()).containsExactly("Teams");
        assertThat(roster.getDescription()).contains("Authz: ADMIN; COACH of this team", "team.roster_exported",
                "guardian");
        assertThat(roster.getDescription()).as("current staff only (decision 83, core 3.6.0)")
                .contains("former coach", "not the export").doesNotContain("may export it too");
        assertThat(parameterNames(roster)).containsExactlyInAnyOrder("X-Tenant-Id", "teamId", "Accept-Language");
    }

    @Test
    void theAuditExportsTakeTheFiltersOfTheirListsWithoutPaging() {
        Operation academy = get(AUDIT);
        Operation platform = get(PLATFORM_AUDIT);

        assertThat(academy.getOperationId()).isEqualTo("exportAuditEvents");
        assertThat(academy.getTags()).containsExactly("Audit");
        assertThat(parameterNames(academy)).containsExactlyInAnyOrder("X-Tenant-Id", "from", "to", "action",
                "Accept-Language");
        assertThat(academy.getDescription()).contains("Authz: ADMIN", "audit.exported", "Platform administrator");
        assertThat(platform.getOperationId()).isEqualTo("exportPlatformAuditEvents");
        assertThat(platform.getTags()).containsExactly("Platform");
        assertThat(parameterNames(platform)).containsExactlyInAnyOrder("tenantId", "from", "to", "action",
                "Accept-Language");
        assertThat(platform.getDescription()).contains("Authz: super_admin", "audit.exported");
    }

    @Test
    void theNewAuditActionsAndTheTeamTargetArePublished() {
        Map<String, io.swagger.v3.oas.models.media.Schema> schemas = CORE.getComponents().getSchemas();

        assertThat(schemas.get("AuditAction").getEnum()).map(String::valueOf)
                .contains("audit.exported", "team.roster_exported");
        assertThat(schemas.get("AuditTargetType").getEnum()).map(String::valueOf).contains("team");
    }

    @Test
    void theStrictValidatorAcceptsACsvFileAndTheFilters() {
        String roster = ROSTER.replace("{teamId}", "0190b6a0-0000-7000-8000-000000000001");
        SimpleResponse file = SimpleResponse.Builder.ok().withContentType("text/csv; charset=utf-8")
                .withHeader("Content-Disposition", "attachment; filename=\"hoops-lions-roster-20261110.csv\"")
                .withHeader("Cache-Control", "no-store").withBody("﻿Role,Given name\r\n").build();

        assertThat(strict.validateResponse(roster, Request.Method.GET, file).hasErrors()).isFalse();
        assertThat(strict.validateResponse(AUDIT, Request.Method.GET, file).hasErrors()).isFalse();
        assertThat(validate(SimpleRequest.Builder.get(AUDIT).withHeader("X-Tenant-Id", TENANT)
                .withHeader("Accept-Language", "es, en;q=0.8").withQueryParam("action", "member.invited")
                .withQueryParam("from", "2026-11-01T00:00:00Z")).hasErrors()).isFalse();
        assertThat(validate(SimpleRequest.Builder.get(AUDIT).withHeader("X-Tenant-Id", TENANT)
                .withQueryParam("action", "member.unknown")).hasErrors()).as("unknown action").isTrue();
        assertThat(validate(SimpleRequest.Builder.get(PLATFORM_AUDIT).withQueryParam("tenantId", TENANT)).hasErrors())
                .isFalse();
    }

    private static ValidationReport validate(SimpleRequest.Builder request) {
        return strict.validateRequest(request.withAuthorization("Bearer test").build());
    }

    private static List<String> parameterNames(Operation operation) {
        List<Parameter> all = new java.util.ArrayList<>(operation.getParameters() == null ? List.of()
                : operation.getParameters());
        CORE.getPaths().values().stream().filter(item -> item.readOperations().contains(operation))
                .flatMap(item -> item.getParameters() == null ? java.util.stream.Stream.empty()
                        : item.getParameters().stream())
                .forEach(all::add);
        return all.stream().map(Parameter::getName).collect(Collectors.toList());
    }
}
