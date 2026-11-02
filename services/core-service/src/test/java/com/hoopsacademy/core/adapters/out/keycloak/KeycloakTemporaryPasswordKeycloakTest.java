package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.testsupport.KeycloakContainerResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.eclipse.microprofile.config.ConfigProvider;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.UserResource;
import org.keycloak.representations.idm.CredentialRepresentation;

/**
 * First sign-in with a temporary password against a real Keycloak 26 with the academy realm (ADR-0024). The password
 * is tried with a direct grant of the test-only client of {@link KeycloakContainerResource}: Keycloak answers
 * "Account is not fully set up" for a correct password with a pending required action and "Invalid user
 * credentials" for a wrong one. Run with {@code ./mvnw -pl services/core-service verify -Pkeycloak-it}.
 */
@Tag("keycloak")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(KeycloakContainerResource.class)
class KeycloakTemporaryPasswordKeycloakTest {

    private static final String NOT_SET_UP = "Account is not fully set up";
    private static final String INVALID = "Invalid user credentials";

    @Inject
    IdentityProviderPort identityProvider;

    @Inject
    Keycloak serviceAccount;

    @Test
    void aTemporaryPasswordHoldsTheLoginAtUpdatePasswordUntilThePersonChoosesTheirOwn() throws Exception {
        String email = unique("first");
        ProvisionedIdentity login = identityProvider.provision(new NewIdentity(email, "First", "Login", AppLocale.EN));
        assertThat(identityProvider.hasOwnPassword(login.subject())).as("no credential yet").isFalse();

        TemporaryPassword temporary = TemporaryPassword.of("Temp-" + UUID.randomUUID().toString().substring(0, 12));
        identityProvider.setTemporaryPassword(login.subject(), temporary);

        assertThat(user(login).toRepresentation().getRequiredActions()).containsExactly("UPDATE_PASSWORD");
        assertThat(directGrant(email, temporary.reveal())).as("correct temporary password").contains(NOT_SET_UP);
        assertThat(directGrant(email, "Wrong-" + UUID.randomUUID())).as("wrong password").contains(INVALID);
        assertThat(identityProvider.hasOwnPassword(login.subject())).as("temporary only").isFalse();

        String chosen = "Chosen-" + UUID.randomUUID();
        user(login).resetPassword(permanent(chosen)); // what the UPDATE_PASSWORD page does at the first sign-in
        assertThat(user(login).toRepresentation().getRequiredActions()).isEmpty();
        assertThat(directGrant(email, chosen)).as("own password").contains("access_token");
        assertThat(identityProvider.hasOwnPassword(login.subject())).isTrue();
        identityProvider.delete(login.subject());
    }

    @Test
    void provisioningAnExistingLoginLeavesItsPasswordAlone() throws Exception {
        String email = unique("existing");
        ProvisionedIdentity created = identityProvider.provision(new NewIdentity(email, "Ex", "Isting", AppLocale.ES));
        String own = "Own-" + UUID.randomUUID();
        user(created).resetPassword(permanent(own));

        ProvisionedIdentity again = identityProvider.provision(new NewIdentity(email, "Ex", "Isting", AppLocale.ES));

        assertThat(again.created()).isFalse();
        assertThat(directGrant(email, own)).contains("access_token");
        assertThat(user(created).toRepresentation().getRequiredActions()).isEmpty();
        identityProvider.delete(created.subject());
    }

    @Test
    void aStuckPendingLoginWithoutAnyCredentialCanBeRepaired() throws Exception {
        String email = unique("stuck");
        ProvisionedIdentity stuck = identityProvider.provision(new NewIdentity(email, "St", "Uck", AppLocale.ID));
        assertThat(serviceAccount.realm("academy").users().get(stuck.subject()).credentials()).isEmpty();

        TemporaryPassword repaired = TemporaryPassword.of("Repair-" + UUID.randomUUID().toString().substring(0, 12));
        identityProvider.setTemporaryPassword(stuck.subject(), repaired);

        assertThat(directGrant(email, repaired.reveal())).contains(NOT_SET_UP);
        identityProvider.delete(stuck.subject());
    }

    private UserResource user(ProvisionedIdentity login) {
        return serviceAccount.realm("academy").users().get(login.subject());
    }

    private static CredentialRepresentation permanent(String value) {
        CredentialRepresentation credential = new CredentialRepresentation();
        credential.setType(CredentialRepresentation.PASSWORD);
        credential.setTemporary(false);
        credential.setValue(value);
        return credential;
    }

    private static String unique(String prefix) {
        return prefix + "-" + UUID.randomUUID() + "@example.com";
    }

    /** The token endpoint's raw answer to a password grant (an error description or the tokens). */
    private static String directGrant(String username, String password) throws Exception {
        String url = ConfigProvider.getConfig().getValue(KeycloakContainerResource.TOKEN_URL, String.class);
        String form = Map.of("grant_type", "password", "client_id", KeycloakContainerResource.DIRECT_GRANT_CLIENT,
                        "username", username, "password", password, "scope", "openid").entrySet().stream()
                .map(e -> e.getKey() + "=" + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form)).build();
        return HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString()).body();
    }
}
