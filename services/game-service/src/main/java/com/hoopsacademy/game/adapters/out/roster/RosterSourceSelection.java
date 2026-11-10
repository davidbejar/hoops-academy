package com.hoopsacademy.game.adapters.out.roster;

import com.hoopsacademy.common.client.RosterAuthzResolver;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.game.adapters.out.client.RestRosterPort;
import com.hoopsacademy.game.application.RosterPort;
import com.hoopsacademy.game.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.game.application.replica.ReplicaRosterPort;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * {@code hoops.roster.source} (ADR-0037): {@code replica} (the default since WP98) reads the local replica fed by
 * core's events, {@code rest} (the fallback) core's {@code /internal} API. One switch for both the {@link RosterPort}
 * and the tenant filter's {@link AuthzContextResolver}, so a request never mixes the two sources. Runtime
 * configuration ({@code GAME_ROSTER_SOURCE}); an unknown value fails the start.
 */
@ApplicationScoped
class RosterSourceSelection {

    /** The values of {@code hoops.roster.source}. */
    enum RosterSource {
        REST,
        REPLICA
    }

    private static final Logger LOG = Logger.getLogger(RosterSourceSelection.class);

    private final RosterSource source;

    RosterSourceSelection(@ConfigProperty(name = "hoops.roster.source", defaultValue = "replica") RosterSource source) {
        this.source = source;
        LOG.infof("Roster source: %s", source.name().toLowerCase(java.util.Locale.ROOT));
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
