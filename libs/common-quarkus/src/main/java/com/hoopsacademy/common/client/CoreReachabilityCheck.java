package com.hoopsacademy.common.client;

import io.quarkus.arc.properties.IfBuildProperty;
import jakarta.enterprise.context.ApplicationScoped;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Readiness;

/**
 * Readiness indicator for core-service. It is informational: the check is always UP and only carries
 * {@code core: reachable|unreachable}, because a core outage must not take this service out of rotation (every
 * request that needs core answers a 503 Problem on its own, ADR-0008). The probe hits core's unauthenticated
 * {@code /q/health/live} with a short timeout and the result is cached ({@code hoops.core.health-cache-ttl}), so
 * frequent kubelet probes neither wait on nor hammer core.
 *
 * <p>Shared by game-service and athlete-service. core-service itself switches it off at build time with
 * {@code hoops.core.reachability-check.enabled=false} (it would only probe itself).
 */
@Readiness
@ApplicationScoped
@IfBuildProperty(name = "hoops.core.reachability-check.enabled", stringValue = "true", enableIfMissing = true)
public class CoreReachabilityCheck implements HealthCheck {

    public static final String NAME = "core-service";

    private final URI liveness;
    private final Duration timeout;
    private final Duration cacheTtl;
    private final Clock clock;
    private final HttpClient http;
    private volatile Instant probedAt = Instant.MIN;
    private volatile boolean reachable;

    public CoreReachabilityCheck(
            @ConfigProperty(name = "hoops.core.url") String coreUrl,
            @ConfigProperty(name = "hoops.core.health-timeout", defaultValue = "PT1S") Duration timeout,
            @ConfigProperty(name = "hoops.core.health-cache-ttl", defaultValue = "PT10S") Duration cacheTtl) {
        this.liveness = URI.create(coreUrl.replaceAll("/+$", "") + "/q/health/live");
        this.timeout = timeout;
        this.cacheTtl = cacheTtl;
        this.clock = Clock.systemUTC();
        this.http = HttpClient.newBuilder().connectTimeout(timeout).build();
    }

    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse.named(NAME)
                .up()
                .withData("core", isReachable() ? "reachable" : "unreachable")
                .build();
    }

    private boolean isReachable() {
        Instant now = clock.instant();
        if (cacheTtl.isZero() || now.isAfter(probedAt.plus(cacheTtl))) {
            reachable = probe();
            probedAt = now;
        }
        return reachable;
    }

    private boolean probe() {
        try {
            HttpRequest request = HttpRequest.newBuilder(liveness).timeout(timeout).GET().build();
            return http.send(request, HttpResponse.BodyHandlers.discarding()).statusCode() == 200;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        } catch (java.io.IOException | RuntimeException e) {
            return false;
        }
    }
}
