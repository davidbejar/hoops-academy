package com.hoopsacademy.athlete.adapters.out.time;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** A request's tenant zone is the caller's context; the registry is only for the jobs (ATH-03). */
class RegistryTenantClockTest {

    static final Instant NOON_UTC = Instant.parse("2031-12-01T12:00:00Z");
    static final TenantId TENANT = TenantId.random();

    final CountingRegistry registry = new CountingRegistry();
    final RegistryTenantClock clock = new RegistryTenantClock(Clock.fixed(NOON_UTC, ZoneOffset.UTC), registry,
            "Europe/Madrid");

    @Test
    void theCallersZoneIsTheTenantZoneWithoutReadingTheRegistry() {
        registry.register(TENANT, ZoneId.of("Pacific/Kiritimati"));

        AuthzContext caller = caller(Optional.of(ZoneId.of("Pacific/Pago_Pago")));

        assertThat(clock.zoneOf(caller)).isEqualTo(ZoneId.of("Pacific/Pago_Pago"));
        assertThat(clock.today(caller)).isEqualTo(LocalDate.of(2031, 12, 1));
        assertThat(registry.lookups).isZero();
    }

    @Test
    void aCallerWithoutAZoneGetsTheLastResortDefault() {
        registry.register(TENANT, ZoneId.of("Pacific/Kiritimati"));

        assertThat(clock.zoneOf(caller(Optional.empty()))).isEqualTo(ZoneId.of("Europe/Madrid"));
        assertThat(registry.lookups).isZero();
    }

    @Test
    void aJobReadsTheZoneTheRegistryHolds() {
        registry.register(TENANT, ZoneId.of("Pacific/Kiritimati"));

        assertThat(clock.zoneOf(TENANT)).isEqualTo(ZoneId.of("Pacific/Kiritimati"));
        assertThat(clock.zoneOf(TenantId.random())).isEqualTo(ZoneId.of("Europe/Madrid"));
        assertThat(clock.now()).isEqualTo(NOON_UTC);
    }

    private static AuthzContext caller(Optional<ZoneId> zone) {
        return new AuthzContext("kc-sub", UUID.randomUUID(), TENANT, Set.of(TenantRole.ADMIN), Set.of(), Set.of(),
                Optional.empty(), Set.of(), zone);
    }

    static final class CountingRegistry implements TenantRegistry {

        final Map<TenantId, ZoneId> zones = new HashMap<>();
        int lookups;

        @Override
        public void register(TenantId tenant, ZoneId zone) {
            zones.put(tenant, zone);
        }

        @Override
        public Optional<ZoneId> zoneOf(TenantId tenant) {
            lookups++;
            return Optional.ofNullable(zones.get(tenant));
        }

        @Override
        public List<TenantId> tenants() {
            return List.copyOf(zones.keySet());
        }
    }
}
