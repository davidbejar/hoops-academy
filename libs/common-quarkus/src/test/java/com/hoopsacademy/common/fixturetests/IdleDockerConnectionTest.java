package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * WP87: the "localhost:2375 failed to respond" flake on a Quarkus restart. The Podman API service closes keep-alive
 * connections idle for 10 s (twice its default {@code --time} of 5 s); docker-java reuses pooled connections without
 * checking them, and once Testcontainers knows the image it sends no GET before the POST that creates the container, so
 * the second database of a JVM failed when its start came more than 10 s after the last Docker call. A Quarkus restart
 * between test classes on a loaded machine pauses that long.
 */
class IdleDockerConnectionTest {

    private static final long LONGER_THAN_THE_PODMAN_API_IDLE_TIMEOUT_MS = 12_000;

    @Test
    void theDatabaseOfTheNextTestClassStartsAfterTheDockerApiConnectionsSatIdle() throws InterruptedException {
        startAndStop();   // the previous test class: image known, connections back in the pool
        Thread.sleep(LONGER_THAN_THE_PODMAN_API_IDLE_TIMEOUT_MS);   // Quarkus restarting under load

        startAndStop();
    }

    private static void startAndStop() {
        PostgresRlsResource resource = new PostgresRlsResource();
        resource.init(Map.of());
        try {
            assertThat(resource.start()).containsKey("quarkus.datasource.jdbc.url");
        } finally {
            resource.stop();
        }
    }
}
