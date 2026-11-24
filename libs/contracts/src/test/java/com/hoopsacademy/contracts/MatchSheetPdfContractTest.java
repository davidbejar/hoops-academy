package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.atlassian.oai.validator.model.SimpleResponse;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.PathItem;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.parameters.Parameter;
import io.swagger.v3.oas.models.responses.ApiResponse;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Game 2.4.0 (WP117, decisions 89 and 90, ADR-0048 amendment): the match sheet (header, score, score by period, box
 * score) as a PDF that game has pdf-service render; one read-only operation answering only {@code application/pdf},
 * readable by whoever reads the box score and with the same player lines.
 */
class MatchSheetPdfContractTest {

    private static final OpenAPI GAME = OpenApiSpecs.parseFullyResolved("game");
    private static final String PATH = "/api/game/matches/{matchId}/box-score:pdf";
    private static final String PDF = "application/pdf";
    private static final String MATCH = "0190b6a0-0000-7000-8000-000000000001";
    private static final String TENANT = "0190b6a0-0000-7000-8000-0000000000aa";

    private static Operation sheet() {
        return GAME.getPaths().get(PATH).getGet();
    }

    @Test
    void theContractIsAtLeastGame240() {
        assertThat(OpenApiSpecs.version("game")).isGreaterThanOrEqualTo(OpenApiSpecs.release("2.4.0"));
    }

    @Test
    void theSheetIsOnePdfFileThatIsNeverCached() {
        PathItem item = GAME.getPaths().get(PATH);
        ApiResponse ok = sheet().getResponses().get("200");

        assertThat(item.readOperations()).as("read-only").hasSize(1);
        assertThat(sheet().getOperationId()).isEqualTo("getMatchSheetPdf");
        assertThat(sheet().getTags()).containsExactly("Statistics");
        assertThat(ok.getContent()).containsOnlyKeys(PDF);
        MediaType pdf = ok.getContent().get(PDF);
        assertThat(pdf.getSchema().getType()).isEqualTo("string");
        assertThat(pdf.getSchema().getFormat()).isEqualTo("binary");
        assertThat(ok.getHeaders()).containsKeys("Content-Disposition", "Cache-Control");
        assertThat(sheet().getResponses()).containsKeys("400", "401", "403", "404", "503");
        assertThat(parameterNames()).containsExactlyInAnyOrder("X-Tenant-Id", "matchId", "Accept-Language");
    }

    @Test
    void theDescriptionNamesTheReadersTheLinesTheFileAndTheOutage() {
        assertThat(sheet().getDescription()).contains("Authz: every member", "getBoxScore", "linked", "own",
                "ADR-0048", "match-sheet", "pdf-service", "UPSTREAM_UNAVAILABLE", "no-store");
    }

    @Test
    void theStrictValidatorAcceptsAPdfAndTheLanguage() {
        OpenApiInteractionValidator strict = OpenApiInteractionValidator
                .createForSpecificationUrl(ContractFiles.openApi("game").toUri().toString()).build();
        String path = PATH.replace("{matchId}", MATCH);
        SimpleResponse file = SimpleResponse.Builder.ok().withContentType(PDF)
                .withHeader("Content-Disposition", "attachment; filename=\"hoops-lions-match-sheet-u14-tigers-20261116.pdf\"")
                .withHeader("Cache-Control", "no-store").withBody("%PDF-1.7").build();

        assertThat(strict.validateResponse(path, Request.Method.GET, file).hasErrors()).isFalse();
        assertThat(strict.validateRequest(SimpleRequest.Builder.get(path).withHeader("X-Tenant-Id", TENANT)
                .withHeader("Accept-Language", "id, en;q=0.8").withAuthorization("Bearer test").build()).hasErrors())
                .isFalse();
    }

    private static List<String> parameterNames() {
        List<Parameter> all = new ArrayList<>(sheet().getParameters() == null ? List.of() : sheet().getParameters());
        List<Parameter> shared = GAME.getPaths().get(PATH).getParameters();
        all.addAll(shared == null ? List.of() : shared);
        return all.stream().map(Parameter::getName).toList();
    }
}
