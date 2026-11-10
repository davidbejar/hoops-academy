package com.hoopsacademy.core.adapters.in.scheduler;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.hoopsacademy.core.application.events.OutboxPublisherStatus;
import com.hoopsacademy.core.application.events.PublishOutbox;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Duration;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * WP91 (FOLLOW-UPS "Events-off producer warnings in core"): {@code hoops.outbox.enabled=false}
 * ({@code CORE_OUTBOX_ENABLED}) keeps the scheduled publisher from running at all, so it never asks the broker adapter
 * for a producer; the outbox rows keep accumulating (the use cases write them regardless).
 */
class OutboxPublisherSwitchTest {

    private final PublishOutbox publisher = mock(PublishOutbox.class);

    private OutboxPublisherJob job(boolean enabled) {
        return new OutboxPublisherJob(publisher, new OutboxPublisherStatus(), new SimpleMeterRegistry(), enabled);
    }

    @Test
    void withEventsOffTheTriggerDoesNotRunThePublisher() {
        job(false).scheduled();

        verify(publisher, never()).run();
    }

    @Test
    void withEventsOnTheTriggerRunsThePublisher() {
        when(publisher.run()).thenReturn(new PublishOutbox.Result(Map.of("core.team", 2), true, 0, Duration.ZERO));

        job(true).scheduled();

        verify(publisher).run();
    }
}
