package com.hoopsacademy.core.adapters.out.keycloak;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.delete;
import static com.github.tomakehurst.wiremock.client.WireMock.equalToJson;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathMatching;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.http.Fault;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Error mapping of the Keycloak adapter against the WireMocked Admin API. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class KeycloakIdentityProviderTest {

    @InjectWireMock
    WireMockServer keycloak;

    @Inject
    IdentityProviderPort identityProvider;

    @BeforeEach
    void defaults() {
        KeycloakStubs.installDefaults(keycloak);
    }

    @Test
    void createsAnEnabledUnverifiedUserNamedByEmailWithLocale() {
        assertThat(identityProvider.provision(new NewIdentity("new@example.com", "New", "User", AppLocale.ID))
                .created()).isTrue();
        keycloak.verify(postRequestedFor(urlEqualTo(KeycloakStubs.USERS)).withRequestBody(equalToJson("""
                {"username":"new@example.com","email":"new@example.com","firstName":"New","lastName":"User",
                 "enabled":true,"emailVerified":false,"attributes":{"locale":["id"]}}""", true, true)));
    }

    @Test
    void refusedCreationIsAnIdentityProviderError() {
        keycloak.stubFor(post(urlEqualTo(KeycloakStubs.USERS)).willReturn(aResponse().withStatus(409)));
        assertThatThrownBy(() -> identityProvider.provision(new NewIdentity("dup@example.com", "D", "U", null)))
                .isInstanceOf(IdentityProviderException.class).hasMessageContaining("409");
    }

    @Test
    void unreachableKeycloakIsAnIdentityProviderError() {
        keycloak.stubFor(post(urlEqualTo(KeycloakStubs.USERS))
                .willReturn(aResponse().withFault(Fault.CONNECTION_RESET_BY_PEER)));
        assertThatThrownBy(() -> identityProvider.provision(new NewIdentity("x@example.com", "X", "Y", null)))
                .isInstanceOf(IdentityProviderException.class);
    }

    @Test
    void deletingAMissingUserIsFineButOtherErrorsAreNot() {
        keycloak.stubFor(delete(urlPathMatching(KeycloakStubs.USERS + "/gone")).willReturn(aResponse().withStatus(404)));
        keycloak.stubFor(delete(urlPathMatching(KeycloakStubs.USERS + "/broken")).willReturn(aResponse().withStatus(500)));
        assertThatCode(() -> identityProvider.delete("gone")).doesNotThrowAnyException();
        assertThatThrownBy(() -> identityProvider.delete("broken")).isInstanceOf(IdentityProviderException.class);
    }
}
