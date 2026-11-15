package com.hoopsacademy.game.adapters.out.client;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.ShippedConfig;
import java.time.Duration;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Where game finds pdf-service as it ships (WP111 handover): {@code PDF_SERVICE_URL} (compose / host
 * {@code http://localhost:8084}, chart {@code http://pdf-service:8084}), unset = no PDF (503), and bounded waits.
 */
class PdfServiceConfigTest {

    @Test
    void theUrlComesFromPdfServiceUrl() {
        ShippedConfig prod = ShippedConfig.load("prod", Map.of("PDF_SERVICE_URL", "http://pdf-service:8084"));

        assertThat(prod.value("hoops.pdf.url")).contains("http://pdf-service:8084");
    }

    @Test
    void withoutPdfServiceUrlThereIsNoUrl() {
        ShippedConfig prod = ShippedConfig.load("prod", Map.of());

        assertThat(prod.value("hoops.pdf.url").filter(url -> !url.isBlank())).isEmpty();
    }

    @Test
    void theWaitsAreBounded() {
        ShippedConfig prod = ShippedConfig.load("prod", Map.of());

        assertThat(prod.value("hoops.pdf.connect-timeout").map(Duration::parse)).hasValueSatisfying(
                timeout -> assertThat(timeout).isPositive().isLessThanOrEqualTo(Duration.ofSeconds(2)));
        assertThat(prod.value("hoops.pdf.read-timeout").map(Duration::parse)).hasValueSatisfying(
                timeout -> assertThat(timeout).isPositive().isLessThanOrEqualTo(Duration.ofSeconds(10)));
    }
}
