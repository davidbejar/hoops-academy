package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.dockerjava.zerodep.shaded.org.apache.hc.core5.http.NoHttpResponseException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.ContainerLaunchException;
import org.testcontainers.lifecycle.Startable;

class ContainerStartsTest {

    private final List<String> calls = new ArrayList<>();
    private final List<Duration> sleeps = new ArrayList<>();

    @Test
    void pingsTheDockerApiBeforeStartingTheContainer() {
        start(new FakeContainer(0));

        assertThat(calls).containsExactly("ping", "start");
        assertThat(sleeps).isEmpty();
    }

    @Test
    void pingsAgainWhileThePooledConnectionsWereClosedWhileIdle() {
        FakeDockerApi api = new FakeDockerApi(2);

        ContainerStarts.start(new FakeContainer(0), api, sleeps::add);

        assertThat(calls).containsExactly("ping", "ping", "ping", "start");
    }

    @Test
    void retriesTheStartWithBackoffWhenItHitAConnectionClosedWhileIdle() {
        start(new FakeContainer(2));

        assertThat(calls).containsExactly("ping", "start", "stop", "ping", "start", "stop", "ping", "start");
        assertThat(sleeps).containsExactly(Duration.ofSeconds(1), Duration.ofSeconds(2));
    }

    @Test
    void givesUpAfterThreeAttempts() {
        FakeContainer container = new FakeContainer(3);

        assertThatThrownBy(() -> start(container)).isInstanceOf(ContainerLaunchException.class);
        assertThat(calls).filteredOn("start"::equals).hasSize(ContainerStarts.MAX_ATTEMPTS);
        assertThat(sleeps).containsExactly(Duration.ofSeconds(1), Duration.ofSeconds(2));
    }

    @Test
    void doesNotRetryOtherStartFailures() {
        Startable broken = new FakeContainer(0) {
            @Override
            public void start() {
                calls.add("start");
                throw new ContainerLaunchException("image not found");
            }
        };

        assertThatThrownBy(() -> start(broken)).hasMessage("image not found");
        assertThat(calls).containsExactly("ping", "start");
        assertThat(sleeps).isEmpty();
    }

    @Test
    void givesUpPingingAfterTheLimit() {
        FakeDockerApi api = new FakeDockerApi(Integer.MAX_VALUE);

        assertThatThrownBy(() -> ContainerStarts.start(new FakeContainer(0), api, sleeps::add))
                .hasRootCauseInstanceOf(NoHttpResponseException.class);
        assertThat(calls).hasSize(ContainerStarts.MAX_PINGS).allMatch("ping"::equals);
    }

    @Test
    void doesNotSwallowOtherPingFailures() {
        ContainerStarts.DockerApi unreachable = () -> {
            calls.add("ping");
            throw new IllegalStateException("Could not find a valid Docker environment");
        };

        assertThatThrownBy(() -> ContainerStarts.start(new FakeContainer(0), unreachable, sleeps::add))
                .hasMessageContaining("valid Docker environment");
        assertThat(calls).containsExactly("ping");
    }

    @Test
    void recognisesAConnectionClosedWhileIdleAnywhereInTheCauseChain() {
        assertThat(ContainerStarts.closedWhileIdle(closedWhileIdle())).isTrue();
        assertThat(ContainerStarts.closedWhileIdle(new ContainerLaunchException("x", new RuntimeException(closedWhileIdle()))))
                .isTrue();
        assertThat(ContainerStarts.closedWhileIdle(new ContainerLaunchException("x", new RuntimeException("other"))))
                .isFalse();
    }

    private void start(Startable container) {
        ContainerStarts.start(container, new FakeDockerApi(0), sleeps::add);
    }

    private static RuntimeException closedWhileIdle() {
        // what docker-java throws for a POST on a pooled connection the Podman API service closed while idle
        return new RuntimeException(new NoHttpResponseException("localhost:2375 failed to respond"));
    }

    private final class FakeDockerApi implements ContainerStarts.DockerApi {
        private int staleConnections;

        FakeDockerApi(int staleConnections) {
            this.staleConnections = staleConnections;
        }

        @Override
        public void ping() {
            calls.add("ping");
            if (staleConnections > 0) {
                staleConnections--;
                throw closedWhileIdle();
            }
        }
    }

    private class FakeContainer implements Startable {
        private int failuresLeft;

        FakeContainer(int failures) {
            this.failuresLeft = failures;
        }

        @Override
        public void start() {
            calls.add("start");
            if (failuresLeft > 0) {
                failuresLeft--;
                throw new ContainerLaunchException("Container startup failed", closedWhileIdle());
            }
        }

        @Override
        public void stop() {
            calls.add("stop");
        }
    }
}
