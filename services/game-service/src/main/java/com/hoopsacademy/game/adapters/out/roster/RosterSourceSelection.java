package com.hoopsacademy.game.adapters.out.roster;

import com.hoopsacademy.common.client.RosterAuthzResolver;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.game.adapters.out.client.RestRosterPort;
import com.hoopsacademy.game.application.RosterPort;
import com.hoopsacademy.game.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.game.application.replica.ReplicaRosterPort;
import io.quarkus.runtime.Startup;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * {@code hoops.roster.source} (ADR-0037): {@code replica} (the default since WP98) reads the local replica fed by
 * core's events, {@code rest} (the fallback) core's {@code /internal} API. One switch for both the {@link RosterPort}
 * and the tenant filter's {@link AuthzContextResolver}, so a request never mixes the two sources. Runtime
 * configuration ({@code GAME_ROSTER_SOURCE}); an unknown value fails the start, and so does {@code replica} without the
 * consumer that feeds it ({@code GAME_ROSTER_CONSUMER_ENABLED=false}: a replica that never changes, WP117), as in
 * athlete.
 */
@ApplicationScoped
@Startup
class RosterSourceSelection {

    /** The values of {@code hoops.roster.source}. */
    enum RosterSource {
        REST,
        REPLICA;

        /** @throws IllegalStateException for the replica without the consumer that feeds it */
        RosterSource requireFed(boolean consume) {
            if (this == REPLICA && !consume) {
                throw new IllegalStateException("hoops.roster.source=replica needs hoops.roster.consumer.enabled=true"
                        + " (GAME_ROSTER_CONSUMER_ENABLED), or the replica never changes; use GAME_ROSTER_SOURCE=rest"
                        + " to run without the consumer");
            }
            return this;
        }
    }

    private static final Logger LOG = Logger.getLogger(RosterSourceSelection.class);

    private final RosterSource source;

    RosterSourceSelection(@ConfigProperty(name = "hoops.roster.source") RosterSource source,
            @ConfigProperty(name = "hoops.roster.consumer.enabled") boolean consume) {
        this.source = source.requireFed(consume);
        LOG.infof("Roster source: %s (replica consumer %s)", source.name().toLowerCase(java.util.Locale.ROOT),
                consume ? "on" : "off");
    }

    @Produces
    @ApplicationScoped
    RosterPort rosterPort(RestRosterPort rest, ReplicaRosterPort replica) {
        return source == RosterSource.REPLICA ? replica : rest;
    }

    @Produces
    @ApplicationScoped
    AuthzContextResolver authzContextResolver(RosterAuthzResolver rest, ReplicaAuthzResolver replica) {
        return source == RosterSource.REPLICA ? replica : rest;
    }
}
