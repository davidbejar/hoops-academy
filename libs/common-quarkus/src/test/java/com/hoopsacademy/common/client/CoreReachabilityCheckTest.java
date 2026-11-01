package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class CoreReachabilityCheckTest {

    private HttpServer core;
    private final AtomicInteger status = new AtomicInteger(200);
    private final AtomicInteger calls = new AtomicInteger();

    @AfterEach
    void stopCore() {
        if (core != null) {
            core.stop(0);
        }
    }

    @Test
    void aLiveCoreIsReachableAndTheCheckIsUp() throws IOException {
        HealthCheckResponse response = check(startCore() + "/", Duration.ZERO).call();

        assertThat(response.getName()).isEqualTo(CoreReachabilityCheck.NAME);
        assertThat(response.getStatus()).isEqualTo(HealthCheckResponse.Status.UP);
        assertThat(response.getData().orElseThrow()).containsEntry("core", "reachable");
        assertThat(calls).hasValue(1);
    }

    @Test
    void aFailingCoreIsUnreachableButTheCheckStaysUp() throws IOException {
        status.set(503);

        HealthCheckResponse response = check(startCore(), Duration.ZERO).call();

        assertThat(response.getStatus()).isEqualTo(HealthCheckResponse.Status.UP);
        assertThat(response.getData().orElseThrow()).containsEntry("core", "unreachable");
    }

    @Test
    void aClosedPortIsUnreachable() throws IOException {
        String url = startCore();
        core.stop(0);
        core = null;

        assertThat(check(url, Duration.ZERO).call().getData().orElseThrow()).containsEntry("core", "unreachable");
    }

    @Test
    void theResultIsCachedForTheTtl() throws IOException {
        CoreReachabilityCheck check = check(startCore(), Duration.ofHours(1));

        check.call();
        status.set(500);
        HealthCheckResponse second = check.call();

        assertThat(calls).hasValue(1);
        assertThat(second.getData().orElseThrow()).containsEntry("core", "reachable");
    }

    private CoreReachabilityCheck check(String coreUrl, Duration cacheTtl) {
        return new CoreReachabilityCheck(coreUrl, Duration.ofSeconds(1), cacheTtl);
    }

    private String startCore() throws IOException {
        core = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        core.createContext("/q/health/live", exchange -> {
            calls.incrementAndGet();
            exchange.sendResponseHeaders(status.get(), -1);
            exchange.close();
        });
        core.start();
        return "http://127.0.0.1:" + core.getAddress().getPort();
    }
}
