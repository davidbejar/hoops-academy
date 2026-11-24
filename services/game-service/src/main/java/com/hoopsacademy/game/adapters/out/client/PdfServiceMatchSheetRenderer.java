package com.hoopsacademy.game.adapters.out.client;

import com.hoopsacademy.common.client.PdfServiceClients;
import com.hoopsacademy.common.client.ServiceTokenClientFilter;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.game.application.sheet.MatchSheet;
import com.hoopsacademy.game.application.sheet.MatchSheetRenderer;
import com.hoopsacademy.game.application.sheet.PdfFile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.time.Duration;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * {@link MatchSheetRenderer} over pdf-service (WP111 handover; ADR-0051 §3, ADR-0052): {@code POST
 * /internal/pdf/match-sheet} at {@code hoops.pdf.url} ({@code PDF_SERVICE_URL}) with game's client-credentials token
 * (audience {@code pdf-service}, ADR-0034), bounded by {@code hoops.pdf.connect-timeout} and {@code read-timeout}.
 * Anything but a PDF back (no URL, unreachable, too slow, a Problem of any status) is an
 * {@link UpstreamUnavailableException} whose message holds the status at most: the body carries players' names and is
 * never logged, put on a span or quoted (docs/security/privacy-threat-model.md). The file name is taken from
 * pdf-service's {@code Content-Disposition} only when it is a plain ADR-0048 name.
 */
@ApplicationScoped
public class PdfServiceMatchSheetRenderer implements MatchSheetRenderer {

    static final String FALLBACK_FILE_NAME = "hoops-match-sheet.pdf";

    private static final Pattern FILE_NAME = Pattern.compile("filename=\"([a-z0-9][a-z0-9-]{0,200}\\.pdf)\"");

    private final Optional<PdfServiceClient> client;

    PdfServiceMatchSheetRenderer(@ConfigProperty(name = "hoops.pdf.url") Optional<URI> url,
            @ConfigProperty(name = "hoops.pdf.connect-timeout") Duration connectTimeout,
            @ConfigProperty(name = "hoops.pdf.read-timeout") Duration readTimeout, ServiceTokenClientFilter token) {
        this.client = PdfServiceClients.build(url, connectTimeout, readTimeout, token, PdfServiceClient.class);
    }

    @Override
    public PdfFile render(MatchSheet sheet) {
        PdfServiceClient pdf = client.orElseThrow(
                () -> new UpstreamUnavailableException("pdf-service is not configured (PDF_SERVICE_URL)", null));
        try (Response answer = pdf.renderMatchSheet(MatchSheetBody.of(sheet))) {
            return file(answer);
        } catch (WebApplicationException e) {
            throw new UpstreamUnavailableException(
                    "pdf-service refused the match sheet with status " + e.getResponse().getStatus(), null);
        } catch (ProcessingException e) {
            throw new UpstreamUnavailableException("pdf-service could not be reached in time", e);
        }
    }

    private static PdfFile file(Response answer) {
        byte[] content = answer.readEntity(byte[].class);
        if (answer.getStatus() != Response.Status.OK.getStatusCode() || !PdfServiceClients.isPdf(content)) {
            throw new UpstreamUnavailableException(
                    "pdf-service answered status " + answer.getStatus() + " without a PDF", null);
        }
        return new PdfFile(content, fileName(answer.getHeaderString(HttpHeaders.CONTENT_DISPOSITION)));
    }

    private static String fileName(String contentDisposition) {
        if (contentDisposition == null) {
            return FALLBACK_FILE_NAME;
        }
        Matcher name = FILE_NAME.matcher(contentDisposition);
        return name.find() ? name.group(1) : FALLBACK_FILE_NAME;
    }
}
