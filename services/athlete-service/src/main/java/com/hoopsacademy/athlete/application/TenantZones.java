package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.ZoneId;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Remembers a tenant and its time zone in the registry. The zone is the tenant's IANA zone carried by the caller's
 * {@link AuthzContext} (core's {@code /internal/authz} answer); when it is absent (an older core) the configured
 * default is registered once and kept.
 */
@ApplicationScoped
public class TenantZones {

    private static final Logger LOG = Logger.getLogger(TenantZones.class);

    private final TenantRegistry registry;
    private final ZoneId defaultZone;

    public TenantZones(TenantRegistry registry,
            @ConfigProperty(name = "hoops.athlete.default-timezone", defaultValue = "Europe/Madrid") String defaultZone) {
        this.registry = registry;
        this.defaultZone = ZoneId.of(defaultZone);
    }

    public void remember(AuthzContext caller) {
        caller.timezone().ifPresentOrElse(zone -> registry.register(caller.tenantId(), zone), () -> {
            registry.registerIfAbsent(caller.tenantId(), defaultZone);
            LOG.debugf("No tenant time zone in the authz context of tenant %s; using %s", caller.tenantId(), defaultZone);
        });
    }
}
