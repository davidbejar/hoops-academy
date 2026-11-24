package com.hoopsacademy.common.client;

import io.quarkus.rest.client.reactive.QuarkusRestClientBuilder;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Arrays;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

/**
 * What core and game share to call pdf-service (ADR-0051 §3, X-06): the client built from the optional
 * {@code hoops.pdf.url} ({@code PDF_SERVICE_URL}; unset means "no PDF", a 503) with the service's own time-outs and
 * its client-credentials token, and the check that an answer is a PDF. Each service keeps its interface (no
 * class-level {@code @Path}: see {@link CoreInternalClient}) and maps failures to {@code UpstreamUnavailableException}.
 */
public final class PdfServiceClients {

    private static final byte[] PDF_MAGIC = "%PDF-".getBytes(StandardCharsets.US_ASCII);

    private PdfServiceClients() {}

    /** The REST client of {@code api} at {@code url}, or empty when no address is configured. */
    public static <T> Optional<T> build(Optional<URI> url, Duration connectTimeout, Duration readTimeout,
            ServiceTokenClientFilter token, Class<T> api) {
        return url.map(base -> QuarkusRestClientBuilder.newBuilder().baseUri(base)
                .connectTimeout(connectTimeout.toMillis(), TimeUnit.MILLISECONDS)
                .readTimeout(readTimeout.toMillis(), TimeUnit.MILLISECONDS)
                .register(token)
                .build(api));
    }

    /** A body that starts with the PDF magic {@code %PDF-}. */
    public static boolean isPdf(byte[] content) {
        return content != null && content.length >= PDF_MAGIC.length
                && Arrays.equals(content, 0, PDF_MAGIC.length, PDF_MAGIC, 0, PDF_MAGIC.length);
    }
}
