package com.hoopsacademy.common.time;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Clock;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

/** Every service gets the UTC wall clock from the library (X-12) unless it or a test brings its own Clock bean. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class ClockProducerTest {

    @Inject
    Clock clock;

    @Test
    void theLibraryProvidesTheUtcWallClock() {
        assertThat(clock.getZone()).isEqualTo(ZoneOffset.UTC);
        assertThat(clock.instant()).isBetween(java.time.Instant.now().minusSeconds(60),
                java.time.Instant.now().plusSeconds(60));
    }
}
