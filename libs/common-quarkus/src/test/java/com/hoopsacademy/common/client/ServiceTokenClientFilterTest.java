package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.quarkus.oidc.client.OidcClient;
import io.quarkus.oidc.client.Tokens;
import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import java.time.Duration;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ServiceTokenClientFilterTest {

    private final OidcClient oidcClient = mock(OidcClient.class);
    private final ClientRequestContext request = mock(ClientRequestContext.class);
    private final MultivaluedMap<String, Object> headers = new MultivaluedHashMap<>();
    private final ServiceTokenClientFilter filter = new ServiceTokenClientFilter(oidcClient);

    @BeforeEach
    void wireHeaders() {
        when(request.getHeaders()).thenReturn(headers);
    }

    private static Tokens tokensExpiringIn(String accessToken, Duration lifetime) {
        long expiresAt = Instant.now().plus(lifetime).getEpochSecond();
        return new Tokens(accessToken, expiresAt, null, null, null, null, "core-service");
    }

    @Test
    void sendsClientCredentialsAccessTokenAsBearer() {
        when(oidcClient.getTokens()).thenReturn(Uni.createFrom().item(tokensExpiringIn("t-1", Duration.ofMinutes(5))));

        filter.filter(request);

        assertThat(headers.getFirst("Authorization")).isEqualTo("Bearer t-1");
    }

    @Test
    void reusesTheTokenUntilItExpires() {
        when(oidcClient.getTokens()).thenReturn(Uni.createFrom().item(tokensExpiringIn("t-1", Duration.ofMinutes(5))));

        filter.filter(request);
        filter.filter(request);

        verify(oidcClient, times(1)).getTokens();
    }

    @Test
    void fetchesANewTokenOnceExpired() {
        when(oidcClient.getTokens())
                .thenReturn(Uni.createFrom().item(tokensExpiringIn("old", Duration.ofMinutes(-1))))
                .thenReturn(Uni.createFrom().item(tokensExpiringIn("new", Duration.ofMinutes(5))));

        filter.filter(request);
        filter.filter(request);

        assertThat(headers.getFirst("Authorization")).isEqualTo("Bearer new");
    }

    @Test
    void failsTheCallWhenNoTokenCanBeObtained() {
        when(oidcClient.getTokens()).thenReturn(Uni.createFrom().failure(new IllegalStateException("idp down")));

        assertThatThrownBy(() -> filter.filter(request)).hasMessageContaining("idp down");
        assertThat(headers).isEmpty();
    }
}
