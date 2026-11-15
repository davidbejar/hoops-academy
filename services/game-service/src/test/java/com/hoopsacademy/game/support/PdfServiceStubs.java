package com.hoopsacademy.game.support;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.atlassian.oai.validator.report.ValidationReport;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.client.ResponseDefinitionBuilder;
import com.github.tomakehurst.wiremock.verification.LoggedRequest;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * pdf-service as the WP111 handover describes it, on the WireMock of {@link CoreWireMockResource}: 200
 * {@code application/pdf} with a body starting {@code %PDF-}, its {@code Content-Disposition} and
 * {@code Cache-Control: no-store}, or a Problem. What game sent is checked against {@code pdf.yaml} (the contracts jar,
 * strict validator: unknown properties and every limit count).
 */
public final class PdfServiceStubs {

    public static final String MATCH_SHEET = "/internal/pdf/match-sheet";
    public static final byte[] PDF = "%PDF-1.7\n% a match sheet\n%%EOF\n".getBytes(StandardCharsets.US_ASCII);
    public static final String FILE_NAME = "hoops-garuda-hoops-match-sheet-u14-elang-tigers-20261116.pdf";

    private static final OpenApiInteractionValidator PDF_CONTRACT =
            OpenApiInteractionValidator.createForSpecificationUrl("/openapi/pdf.yaml").build();

    private PdfServiceStubs() {}

    /** pdf-service renders every match sheet as {@link #PDF} named {@link #FILE_NAME}. */
    public static void rendersMatchSheets(WireMockServer wm) {
        wm.stubFor(post(urlPathEqualTo(MATCH_SHEET)).willReturn(aResponse().withStatus(200)
                .withHeader("Content-Type", "application/pdf")
                .withHeader("Content-Disposition", "attachment; filename=\"" + FILE_NAME + "\"")
                .withHeader("Cache-Control", "no-store").withBody(PDF)));
    }

    /** pdf-service answers every match sheet with {@code response}. */
    public static void answersMatchSheets(WireMockServer wm, ResponseDefinitionBuilder response) {
        wm.stubFor(post(urlPathEqualTo(MATCH_SHEET)).willReturn(response));
    }

    /** A Problem of pdf-service ({@code violations} name fields, never values: WP111). */
    public static ResponseDefinitionBuilder problem(int status, String code) {
        return aResponse().withStatus(status).withHeader("Content-Type", "application/problem+json")
                .withBody("{\"type\":\"about:blank\",\"title\":\"refused\",\"status\":" + status + ",\"code\":\"" + code
                        + "\"}");
    }

    /** The match sheets game sent, oldest first. */
    public static List<LoggedRequest> sentMatchSheets(WireMockServer wm) {
        return wm.findAll(postRequestedFor(urlPathEqualTo(MATCH_SHEET)));
    }

    /** The checks of {@code pdf.yaml} {@code renderMatchSheet} on a request game sent. */
    public static ValidationReport againstTheContract(LoggedRequest sent) {
        SimpleRequest.Builder request = SimpleRequest.Builder.post(MATCH_SHEET)
                .withContentType(sent.getHeader("Content-Type")).withBody(sent.getBodyAsString());
        if (sent.containsHeader("Authorization")) {
            request.withAuthorization(sent.getHeader("Authorization"));
        }
        return PDF_CONTRACT.validateRequest(request.build());
    }
}
