package com.hoopsacademy.athlete.adapters.out.time;

import io.quarkus.arc.DefaultBean;
import jakarta.inject.Singleton;
import jakarta.enterprise.inject.Produces;
import java.time.Clock;

/** The wall clock; a test may override it with an alternative {@link Clock} bean. */
class ClockProducer {

    @Produces
    @DefaultBean
    @Singleton
    Clock clock() {
        return Clock.systemUTC();
    }
}
