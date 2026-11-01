package com.hoopsacademy.core.adapters.config;

import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import java.time.Clock;

/** UTC system clock; tests may replace it with an alternative. */
class ClockProducer {

    @Produces
    @Singleton
    Clock clock() {
        return Clock.systemUTC();
    }
}
