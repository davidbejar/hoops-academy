package com.hoopsacademy.athlete.adapters.config;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.adapters.out.persistence.ReplicaRosterRepository;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.client.RosterAuthzResolver;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import io.quarkus.runtime.Startup;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * hoops.roster.source picks the {@link RosterPort} of the use cases and the tenant filter's
 * {@link AuthzContextResolver}: the local replica (default since WP98) or core's REST API (the fallback). Both adapters
 * exist either way (the replica fills from its consumer while REST answers); only the produced beans follow the switch.
 * A replica without its consumer fails the startup.
 */
@ApplicationScoped
@Startup
public class RosterSourceProducer {

    private static final Logger LOG = Logger.getLogger(RosterSourceProducer.class);

    private final RosterSource source;

    RosterSourceProducer(@ConfigProperty(name = "hoops.roster.source", defaultValue = "replica") String source,
            @ConfigProperty(name = "hoops.roster.consumer.enabled", defaultValue = "true") boolean consume) {
        this.source = RosterSource.of(source, consume);
        LOG.infof("Roster source: %s (replica consumer %s)", this.source, consume ? "on" : "off");
    }

    @Produces
    @ApplicationScoped
    RosterPort rosterPort(CoreRosterAdapter rest, ReplicaRosterRepository replica) {
        return source == RosterSource.REPLICA ? replica : rest;
    }

    @Produces
    @ApplicationScoped
    AuthzContextResolver membership(CoreRosterClient core, ReplicaAuthzResolver replica) {
        return source == RosterSource.REPLICA ? replica : new RosterAuthzResolver(core);
    }
}
