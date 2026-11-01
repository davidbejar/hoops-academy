package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Short-lived cache of membership lookups per (subject, tenant), so the tenant filter does not hit the database on
 * every request. Writes in this instance invalidate the tenant at once; other replicas converge within the TTL.
 */
@ApplicationScoped
public class AuthzCache {

    private record Key(String subject, TenantId tenant) {}

    private record Entry(Optional<MemberAuthz> value, Instant expiresAt) {}

    private final Map<Key, Entry> entries = new ConcurrentHashMap<>();
    private final Duration ttl;
    private final Clock clock;

    public AuthzCache(@ConfigProperty(name = "hoops.authz.cache-ttl", defaultValue = "PT10S") Duration ttl, Clock clock) {
        this.ttl = ttl;
        this.clock = clock;
    }

    public Optional<MemberAuthz> get(String subject, TenantId tenant, Supplier<Optional<MemberAuthz>> loader) {
        Key key = new Key(subject, tenant);
        Instant now = clock.instant();
        Entry cached = entries.get(key);
        if (cached != null && now.isBefore(cached.expiresAt())) {
            return cached.value();
        }
        Optional<MemberAuthz> loaded = loader.get();
        entries.put(key, new Entry(loaded, now.plus(ttl)));
        return loaded;
    }

    public void invalidate(TenantId tenant) {
        entries.keySet().removeIf(key -> key.tenant().equals(tenant));
    }
}
