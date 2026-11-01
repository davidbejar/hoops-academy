package com.hoopsacademy.core.application.authz;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

class AuthzCacheTest {

    private final TenantId tenant = TenantId.random();
    private final MutableClock clock = new MutableClock();
    private final AuthzCache cache = new AuthzCache(Duration.ofSeconds(10), clock);
    private final AtomicInteger loads = new AtomicInteger();

    @Test
    void cachesForTheTtlThenReloads() {
        assertThat(load()).isPresent();
        clock.advance(Duration.ofSeconds(9));
        load();
        assertThat(loads).hasValue(1);
        clock.advance(Duration.ofSeconds(1));
        load();
        assertThat(loads).hasValue(2);
    }

    @Test
    void invalidationDropsOnlyThatTenant() {
        TenantId other = TenantId.random();
        load();
        cache.get("sub", other, () -> {
            loads.incrementAndGet();
            return Optional.empty();
        });
        cache.invalidate(tenant);
        load();
        cache.get("sub", other, () -> {
            loads.incrementAndGet();
            return Optional.empty();
        });
        assertThat(loads).hasValue(3);
    }

    private Optional<MemberAuthz> load() {
        return cache.get("sub", tenant, () -> {
            loads.incrementAndGet();
            return Optional.of(new MemberAuthz(new AuthzContext("sub", UUID.randomUUID(), tenant, Set.of(), Set.of(),
                    Set.of(), Optional.empty()), TenantStatus.ACTIVE));
        });
    }

    private static final class MutableClock extends Clock {
        private Instant now = Instant.parse("2026-11-01T00:00:00Z");

        void advance(Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }
}
