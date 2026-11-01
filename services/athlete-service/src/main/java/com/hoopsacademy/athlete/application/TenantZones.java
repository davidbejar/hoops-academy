package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.ZoneId;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Remembers a tenant and its time zone in the registry. The zone comes from core's authz answer when it carries
 * one; until the contract does, the configured default is registered once and kept.
 */
@ApplicationScoped
public class TenantZones {

    private static final Logger LOG = Logger.getLogger(TenantZones.class);

    private final RosterPort roster;
    private final TenantRegistry registry;
    private final ZoneId defaultZone;

    public TenantZones(RosterPort roster, TenantRegistry registry,
            @ConfigProperty(name = "hoops.athlete.default-timezone", defaultValue = "Europe/Madrid") String defaultZone) {
        this.roster = roster;
        this.registry = registry;
        this.defaultZone = ZoneId.of(defaultZone);
    }

    public void remember(AuthzContext caller) {
        ZoneId reported = roster.authzContext(caller.tenantId(), caller.subject())
                .flatMap(MemberContext::tenantZone)
                .orElse(null);
        if (reported != null) {
            registry.register(caller.tenantId(), reported);
        } else {
            registry.registerIfAbsent(caller.tenantId(), defaultZone);
            LOG.debugf("core reported no time zone for tenant %s; using %s", caller.tenantId(), defaultZone);
        }
    }
}
