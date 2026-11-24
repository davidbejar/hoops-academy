package com.hoopsacademy.common.time;

import io.quarkus.arc.DefaultBean;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import java.time.Clock;

/**
 * The UTC wall clock every service injects (X-12); {@code ReplicaRetention} and the use cases read time through it. A
 * service or a test replaces it with its own {@link Clock} bean.
 */
public class ClockProducer {

    @Produces
    @DefaultBean
    @Singleton
    Clock clock() {
        return Clock.systemUTC();
    }
}
