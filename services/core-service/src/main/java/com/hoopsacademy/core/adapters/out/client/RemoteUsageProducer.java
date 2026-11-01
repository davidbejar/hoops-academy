package com.hoopsacademy.core.adapters.out.client;

import com.hoopsacademy.core.application.port.RemoteUsagePort;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.eclipse.microprofile.rest.client.inject.RestClient;

/** One {@link RemoteUsagePort} per downstream service (consumed as {@code Instance<RemoteUsagePort>}). */
@ApplicationScoped
class RemoteUsageProducer {

    @Produces
    @ApplicationScoped
    RemoteUsagePort game(@RestClient GameUsageClient client) {
        return new RemoteUsage("game", client::usage);
    }

    @Produces
    @ApplicationScoped
    RemoteUsagePort athlete(@RestClient AthleteUsageClient client) {
        return new RemoteUsage("athlete", client::usage);
    }
}
