package com.hoopsacademy.core.adapters.out.keycloak;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.delete;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.equalToJson;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.putRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathMatching;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.http.Fault;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.LoginUpdate;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
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

    private static final String FAKE_PASSWORD = "Fake-Temp-Value-7";

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
    void updateLoginMovesUsernameAndEmailAndSendsNoMail() {
        KeycloakStubs.login(keycloak, "moving", "old@example.com");
        identityProvider.updateLogin(new LoginUpdate("moving", "new@example.com", "New", "Name"));
        keycloak.verify(KeycloakStubs.loginMoved("moving", "new@example.com").withRequestBody(equalToJson("""
                {"firstName":"New","lastName":"Name","enabled":true}""", true, true)));
        keycloak.verify(0, KeycloakStubs.anySetupEmail());
        keycloak.verify(0, KeycloakStubs.anyPasswordReset());
    }

    @Test
    void anEmailOwnedByAnotherLoginIsAConflict() {
        KeycloakStubs.login(keycloak, "clash", "mine@example.com");
        KeycloakStubs.loginUpdateConflicts(keycloak);
        assertThatThrownBy(() -> identityProvider.updateLogin(
                new LoginUpdate("clash", "taken@example.com", "C", "L")))
                .isInstanceOf(ConflictException.class).extracting("code").isEqualTo("EMAIL_TAKEN");
    }

    @Test
    void aFailedUpdateIsAnIdentityProviderError() {
        KeycloakStubs.login(keycloak, "broken", "b@example.com");
        KeycloakStubs.loginUpdateFails(keycloak);
        assertThatThrownBy(() -> identityProvider.updateLogin(
                new LoginUpdate("broken", "n@example.com", "B", "R")))
                .isInstanceOf(IdentityProviderException.class);
    }

    @Test
    void setsATemporaryPasswordCredential() {
        identityProvider.setTemporaryPassword("fresh", TemporaryPassword.of(FAKE_PASSWORD));
        keycloak.verify(putRequestedFor(urlEqualTo(KeycloakStubs.USERS + "/fresh/reset-password"))
                .withRequestBody(equalToJson("""
                        {"type":"password","temporary":true,"value":"%s"}""".formatted(FAKE_PASSWORD), true, true)));
        keycloak.verify(0, KeycloakStubs.anySetupEmail());
    }

    @Test
    void aRefusedTemporaryPasswordIsAnIdentityProviderErrorWithoutTheValue() {
        KeycloakStubs.temporaryPasswordFails(keycloak);
        assertThatThrownBy(() -> identityProvider.setTemporaryPassword("refused", TemporaryPassword.of(FAKE_PASSWORD)))
                .isInstanceOf(IdentityProviderException.class)
                .satisfies(e -> assertThat(stackTraceOf(e)).doesNotContain(FAKE_PASSWORD));
    }

    @Test
    void ownPasswordMeansAPasswordCredentialWithoutPendingUpdate() {
        assertThat(identityProvider.hasOwnPassword("no-credential")).as("no credential at all").isFalse();
        KeycloakStubs.temporaryPassword(keycloak, "temporary");
        assertThat(identityProvider.hasOwnPassword("temporary")).as("temporary password pending").isFalse();
        KeycloakStubs.ownPassword(keycloak, "chosen");
        assertThat(identityProvider.hasOwnPassword("chosen")).as("password chosen").isTrue();
    }

    @Test
    void anUnreadableLoginIsAnIdentityProviderError() {
        keycloak.stubFor(get(urlPathMatching(KeycloakStubs.USERS + "/broken/credentials"))
                .willReturn(aResponse().withStatus(500)));
        assertThatThrownBy(() -> identityProvider.hasOwnPassword("broken"))
                .isInstanceOf(IdentityProviderException.class);
    }

    private static String stackTraceOf(Throwable e) {
        java.io.StringWriter trace = new java.io.StringWriter();
        e.printStackTrace(new java.io.PrintWriter(trace));
        return trace.toString();
    }

    @Test
    void deletingAMissingUserIsFineButOtherErrorsAreNot() {
        keycloak.stubFor(delete(urlPathMatching(KeycloakStubs.USERS + "/gone")).willReturn(aResponse().withStatus(404)));
        keycloak.stubFor(delete(urlPathMatching(KeycloakStubs.USERS + "/broken")).willReturn(aResponse().withStatus(500)));
        assertThatCode(() -> identityProvider.delete("gone")).doesNotThrowAnyException();
        assertThatThrownBy(() -> identityProvider.delete("broken")).isInstanceOf(IdentityProviderException.class);
    }
}
