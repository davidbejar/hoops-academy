package com.hoopsacademy.common.client;

import io.quarkus.oidc.client.OidcClient;
import io.quarkus.oidc.client.Tokens;
import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import java.time.Duration;

/**
 * Authenticates service-to-service calls with a client-credentials token from the default
 * {@code quarkus-oidc-client} ({@code quarkus.oidc-client.*}); the token is cached until it expires or enters the
 * refresh interval. Register with {@code @RegisterProvider(ServiceTokenClientFilter.class)}. It blocks while
 * fetching a token, so call such clients from worker threads (blocking use cases), not the event loop.
 */
@ApplicationScoped
@Priority(Priorities.AUTHENTICATION)
public class ServiceTokenClientFilter implements ClientRequestFilter {

    private static final Duration TOKEN_TIMEOUT = Duration.ofSeconds(10);

    private final OidcClient oidcClient;
    private Tokens tokens;

    public ServiceTokenClientFilter(OidcClient oidcClient) {
        this.oidcClient = oidcClient;
    }

    @Override
    public void filter(ClientRequestContext request) {
        request.getHeaders().putSingle(HttpHeaders.AUTHORIZATION, "Bearer " + currentAccessToken());
    }

    private synchronized String currentAccessToken() {
        if (tokens == null || tokens.isAccessTokenExpired() || tokens.isAccessTokenWithinRefreshInterval()) {
            tokens = oidcClient.getTokens().await().atMost(TOKEN_TIMEOUT);
        }
        return tokens.getAccessToken();
    }
}
