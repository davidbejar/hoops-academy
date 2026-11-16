package com.hoopsacademy.core.adapters.out.client;

import com.hoopsacademy.common.client.ServiceTokenClientFilter;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.core.application.export.RosterPrint;
import com.hoopsacademy.core.application.port.RosterPrinter;
import io.quarkus.rest.client.reactive.QuarkusRestClientBuilder;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.WebApplicationException;
import java.net.URI;
import java.time.Duration;
import java.util.Optional;
import java.util.concurrent.TimeUnit;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Prints the team roster through pdf-service (WP116, ADR-0051 §3) at {@code hoops.pdf-service.url}
 * ({@code PDF_SERVICE_URL}), with core's client-credentials token ({@code aud} pdf-service, ADR-0034) and short
 * time-outs, since the export's transaction waits for the answer. Unset, unreachable, too slow, an error status or an
 * empty answer: {@link UpstreamUnavailableException} (503), whose message names the cause only; the body sent is never
 * logged.
 */
@ApplicationScoped
class PdfServiceRosterPrinter implements RosterPrinter {

    private final Optional<PdfServiceClient> client;

    @Inject
    PdfServiceRosterPrinter(@ConfigProperty(name = "hoops.pdf-service.url") Optional<URI> url,
            @ConfigProperty(name = "hoops.pdf-service.connect-timeout") Duration connectTimeout,
            @ConfigProperty(name = "hoops.pdf-service.read-timeout") Duration readTimeout,
            ServiceTokenClientFilter serviceToken) {
        this(url.map(base -> QuarkusRestClientBuilder.newBuilder().baseUri(base)
                .connectTimeout(connectTimeout.toMillis(), TimeUnit.MILLISECONDS)
                .readTimeout(readTimeout.toMillis(), TimeUnit.MILLISECONDS)
                .register(serviceToken)
                .build(PdfServiceClient.class)));
    }

    PdfServiceRosterPrinter(Optional<PdfServiceClient> client) {
        this.client = client;
    }

    @Override
    public byte[] print(RosterPrint roster) {
        PdfServiceClient pdf = client.orElseThrow(
                () -> new UpstreamUnavailableException("pdf-service is not configured (PDF_SERVICE_URL)", null));
        byte[] sheet = render(pdf, TeamRosterRequestDto.of(roster));
        if (sheet == null || sheet.length == 0) {
            throw new UpstreamUnavailableException("pdf-service answered no sheet", null);
        }
        return sheet;
    }

    private static byte[] render(PdfServiceClient pdf, TeamRosterRequestDto request) {
        try {
            return pdf.teamRoster(request);
        } catch (WebApplicationException e) {
            throw new UpstreamUnavailableException("pdf-service answered " + e.getResponse().getStatus(), e);
        } catch (RuntimeException e) {
            throw new UpstreamUnavailableException(
                    "pdf-service is not reachable (" + e.getClass().getSimpleName() + ")", e);
        }
    }
}
