package com.hoopsacademy.common.testing;

import com.github.dockerjava.zerodep.shaded.org.apache.hc.core5.http.NoHttpResponseException;
import java.time.Duration;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.lifecycle.Startable;

/**
 * Starts a Testcontainers container despite Docker API connections that the Podman API service closed while idle
 * (WP87, the "localhost:2375 failed to respond" flake).
 *
 * <p>Cause: {@code podman system service} (the Podman machine's API, default {@code --time 5}) closes keep-alive
 * connections after 10 s idle. docker-java 3.7 pools connections without validating them before reuse
 * ({@code validateAfterInactivity} -1). Apache HttpClient re-sends an idempotent request (GET) that met a closed
 * connection by itself and drops that connection, but not a POST: once Testcontainers knows an image it sends the POST
 * that creates the container first, which then fails. A Quarkus restart between test classes on a loaded machine is
 * the pause that leaves the pool stale ({@code IdleDockerConnectionTest} reproduces it on any machine).
 *
 * <p>Fix: a GET ({@code /_ping}) before every start replaces the dead connections, so the create runs on a live one.
 * If a start still meets one, it is retried with backoff, at most {@link #MAX_ATTEMPTS} times; other failures are not.
 */
public final class ContainerStarts {

    static final int MAX_ATTEMPTS = 3;
    static final int MAX_PINGS = 10;

    /** The Docker API call that refreshes the connection pool (an idempotent GET). */
    @FunctionalInterface
    interface DockerApi {
        void ping();
    }

    @FunctionalInterface
    interface Sleeper {
        void sleep(Duration duration) throws InterruptedException;
    }

    private ContainerStarts() {}

    /** Starts {@code container} through the shared Testcontainers Docker client. */
    public static void start(Startable container) {
        start(container, () -> DockerClientFactory.instance().client().pingCmd().exec(),
                duration -> Thread.sleep(duration.toMillis()));
    }

    static void start(Startable container, DockerApi api, Sleeper sleeper) {
        for (int attempt = 1; ; attempt++) {
            refreshConnections(api);
            try {
                container.start();
                return;
            } catch (RuntimeException e) {
                if (attempt == MAX_ATTEMPTS || !closedWhileIdle(e)) {
                    throw e;
                }
                container.stop();
                pause(sleeper, Duration.ofSeconds(attempt));
            }
        }
    }

    /** Each failed ping drops the closed connections it met; one that answers leaves a live connection on top. */
    private static void refreshConnections(DockerApi api) {
        for (int ping = 1; ; ping++) {
            try {
                api.ping();
                return;
            } catch (RuntimeException e) {
                if (ping == MAX_PINGS || !closedWhileIdle(e)) {
                    throw e;
                }
            }
        }
    }

    static boolean closedWhileIdle(Throwable failure) {
        for (Throwable t = failure; t != null; t = t.getCause()) {
            if (t instanceof NoHttpResponseException) {
                return true;
            }
        }
        return false;
    }

    private static void pause(Sleeper sleeper, Duration duration) {
        try {
            sleeper.sleep(duration);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("interrupted while waiting to retry a container start", e);
        }
    }
}
