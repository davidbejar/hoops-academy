package com.hoopsacademy.core.adapters.in.health;

import com.hoopsacademy.core.application.events.OutboxPublisherStatus;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.HealthCheckResponseBuilder;
import org.eclipse.microprofile.health.Readiness;

/**
 * The outbox publisher on /q/health/ready: always UP, so a broker outage never takes core out of service (the API only
 * writes the outbox; the events wait there), with {@code state} DEGRADED while the last run could not reach the broker
 * and the backlog it saw. The Kafka connector's own readiness check is off (channel {@code health-enabled=false}).
 */
@Readiness
@ApplicationScoped
public class OutboxPublisherHealthCheck implements HealthCheck {

    static final String NAME = "outbox-publisher";

    private final OutboxPublisherStatus status;

    public OutboxPublisherHealthCheck(OutboxPublisherStatus status) {
        this.status = status;
    }

    @Override
    public HealthCheckResponse call() {
        OutboxPublisherStatus.Snapshot snapshot = status.snapshot();
        HealthCheckResponseBuilder response = HealthCheckResponse.named(NAME).up()
                .withData("state", snapshot.degraded() ? "DEGRADED" : "OK")
                .withData("pending", snapshot.pending())
                .withData("lagSeconds", snapshot.lag().toSeconds());
        snapshot.lastRun().ifPresent(at -> response.withData("lastRun", at.toString()));
        snapshot.lastError().ifPresent(error -> response.withData("lastError", error));
        return response.build();
    }
}
