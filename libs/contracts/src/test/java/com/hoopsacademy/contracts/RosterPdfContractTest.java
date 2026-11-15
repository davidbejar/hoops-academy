package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleResponse;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.responses.ApiResponse;
import java.lang.module.ModuleDescriptor;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Core 3.7.0 (WP116, decision 89, ADR-0048 amendment): the team roster export also answers a printable PDF when the
 * caller asks for {@code Accept: application/pdf}; core renders it through pdf-service (ADR-0051 §3), which can be
 * unavailable (503). The audit read names a {@code team} target.
 */
class RosterPdfContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parseFullyResolved("core");
    private static final String ROSTER = "/api/core/teams/{teamId}/roster:export";
    private static final String PDF = "application/pdf";

    private static OpenApiInteractionValidator strict;

    @BeforeAll
    static void strictValidator() {
        strict = OpenApiInteractionValidator.createForSpecificationUrl(ContractFiles.openApi("core").toUri().toString())
                .build();
    }

    private static Operation roster() {
        return CORE.getPaths().get(ROSTER).getGet();
    }

    @Test
    void coreIsAtLeast370() {
        assertThat(ModuleDescriptor.Version.parse(CORE.getInfo().getVersion()))
                .isGreaterThanOrEqualTo(ModuleDescriptor.Version.parse("3.7.0"));
    }

    @Test
    void theRosterExportIsACsvOrAPdfFileByAccept() {
        ApiResponse ok = roster().getResponses().get("200");

        assertThat(ok.getContent()).containsOnlyKeys("text/csv", PDF);
        MediaType pdf = ok.getContent().get(PDF);
        assertThat(pdf.getSchema().getType()).isEqualTo("string");
        assertThat(pdf.getSchema().getFormat()).isEqualTo("binary");
        assertThat(roster().getOperationId()).as("one operation, as the CSV").isEqualTo("exportTeamRoster");
        assertThat(roster().getDescription()).contains("Accept: application/pdf", "pdf-service", "format",
                "hoops-<academy-slug>-roster-<team>-<yyyyMMdd>.pdf", "60 players", "20 staff");
    }

    @Test
    void anUnavailablePdfServiceIsA503ProblemThatAuditsNothing() {
        ApiResponse unavailable = roster().getResponses().get("503");

        assertThat(unavailable).isNotNull();
        assertThat(unavailable.getContent()).containsOnlyKeys("application/problem+json");
        assertThat(unavailable.getDescription()).contains("UPSTREAM_UNAVAILABLE", "pdf-service", "retry");
    }

    @Test
    void theStrictValidatorAcceptsAPdfFile() {
        String path = ROSTER.replace("{teamId}", "0190b6a0-0000-7000-8000-000000000001");
        SimpleResponse file = SimpleResponse.Builder.ok().withContentType(PDF)
                .withHeader("Content-Disposition", "attachment; filename=\"hoops-lions-roster-u12-20261116.pdf\"")
                .withHeader("Cache-Control", "no-store").withBody("%PDF-1.7").build();
        SimpleResponse problem = SimpleResponse.Builder.status(503).withContentType("application/problem+json")
                .withBody("{\"type\":\"about:blank\",\"title\":\"Service Unavailable\",\"status\":503,"
                        + "\"code\":\"UPSTREAM_UNAVAILABLE\"}")
                .build();

        assertThat(strict.validateResponse(path, Request.Method.GET, file).hasErrors()).isFalse();
        assertThat(strict.validateResponse(path, Request.Method.GET, problem).getMessages()).isEmpty();
    }

    @Test
    void aTeamTargetIsNamed() {
        Schema<?> target = CORE.getComponents().getSchemas().get("AuditTarget");
        Schema<?> displayName = (Schema<?>) target.getProperties().get("displayName");

        assertThat(displayName.getDescription()).contains("team", "3.7.0");
    }
}
