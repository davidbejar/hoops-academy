package com.hoopsacademy.core.application.authz;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.function.Supplier;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Short-lived cache of membership lookups per (subject, tenant), so the tenant filter does not hit the database on
 * every request. Writes in this instance invalidate the tenant at once; other replicas converge within the TTL.
 * Expired entries are evicted, and at most {@value #MAX_ENTRIES} are kept (Caffeine, timed by the injected clock).
 */
@ApplicationScoped
public class AuthzCache {

    static final int MAX_ENTRIES = 10_000;

    private record Key(String subject, TenantId tenant) {}

    private final Cache<Key, Optional<MemberAuthz>> entries;

    @Inject
    public AuthzCache(@ConfigProperty(name = "hoops.authz.cache-ttl", defaultValue = "PT10S") Duration ttl, Clock clock) {
        this(ttl, clock, MAX_ENTRIES);
    }

    AuthzCache(Duration ttl, Clock clock, int maxEntries) {
        this.entries = Caffeine.newBuilder()
                .expireAfterWrite(ttl)
                .maximumSize(maxEntries)
                .ticker(() -> ChronoUnit.NANOS.between(Instant.EPOCH, clock.instant()))
                .executor(Runnable::run)
                .build();
    }

    /** The loader runs outside the cache's locks; a concurrent miss may load twice, as before. */
    public Optional<MemberAuthz> get(String subject, TenantId tenant, Supplier<Optional<MemberAuthz>> loader) {
        Key key = new Key(subject, tenant);
        Optional<MemberAuthz> cached = entries.getIfPresent(key);
        if (cached != null) {
            return cached;
        }
        Optional<MemberAuthz> loaded = loader.get();
        entries.put(key, loaded);
        return loaded;
    }

    public void invalidate(TenantId tenant) {
        entries.asMap().keySet().removeIf(key -> key.tenant().equals(tenant));
    }

    /** Live entries, after evicting the expired ones. */
    long size() {
        entries.cleanUp();
        return entries.estimatedSize();
    }
}
