package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.LoginUpdate;
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
import java.time.Duration;
import java.util.UUID;
import org.eclipse.microprofile.config.ConfigProvider;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.UsersResource;
import org.keycloak.representations.idm.UserRepresentation;

/**
 * {@code updateLogin} against a real Keycloak 26 with the academy realm (username = e-mail) and a MailHog SMTP
 * server, which must stay empty: moving a login sends no mail (ADR-0024). Run with {@code ./mvnw -pl services/core-service verify -Pkeycloak-it}.
 */
@Tag("keycloak")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(value = KeycloakContainerResource.class, initArgs = @ResourceArg(name = "mail", value = "true"))
class KeycloakLoginUpdateKeycloakTest {

    @Inject
    IdentityProviderPort identityProvider;

    @Inject
    Keycloak serviceAccount;

    @Test
    void updateLoginMovesUsernameAndEmailWithoutAnyMailAndKeepsThePassword() throws Exception {
        String old = unique("old");
        ProvisionedIdentity login = identityProvider.provision(new NewIdentity(old, "Old", "Name", AppLocale.EN));
        TemporaryPassword temporary = TemporaryPassword.of("Move-" + UUID.randomUUID().toString().substring(0, 12));
        identityProvider.setTemporaryPassword(login.subject(), temporary);
        String moved = unique("moved");

        identityProvider.updateLogin(new LoginUpdate(login.subject(), moved, "New", "Person"));

        UserRepresentation stored = users().get(login.subject()).toRepresentation();
        assertThat(stored.getUsername()).isEqualTo(moved);
        assertThat(stored.getEmail()).isEqualTo(moved);
        assertThat(stored.getFirstName()).isEqualTo("New");
        assertThat(stored.getLastName()).isEqualTo("Person");
        assertThat(stored.getRequiredActions()).containsExactly("UPDATE_PASSWORD");
        assertThat(users().searchByEmail(old, true)).isEmpty();
        assertThat(users().searchByUsername(moved, true)).extracting(UserRepresentation::getId)
                .containsExactly(login.subject());
        assertThat(directGrant(moved, temporary.reveal())).as("same temporary password under the new username")
                .contains("Account is not fully set up");
        assertThat(mailsTo(moved)).as("no mail to the new address").contains("\"total\":0");
        assertThat(mailsTo(old)).as("no mail to the old address").contains("\"total\":0");
        identityProvider.delete(login.subject());
    }

    @Test
    void anotherLoginsEmailIsAConflictAndChangesNothing() {
        String taken = unique("taken");
        ProvisionedIdentity owner = identityProvider.provision(new NewIdentity(taken, "Own", "Er", AppLocale.EN));
        String mine = unique("mine");
        ProvisionedIdentity login = identityProvider.provision(new NewIdentity(mine, "Me", "Too", AppLocale.EN));

        assertThatThrownBy(() -> identityProvider.updateLogin(
                new LoginUpdate(login.subject(), taken, "Me", "Too")))
                .isInstanceOf(ConflictException.class);
        assertThat(users().get(login.subject()).toRepresentation().getUsername()).isEqualTo(mine);
        identityProvider.delete(owner.subject());
        identityProvider.delete(login.subject());
    }

    private UsersResource users() {
        return serviceAccount.realm("academy").users();
    }

    private static String unique(String prefix) {
        return prefix + "-" + UUID.randomUUID() + "@example.com";
    }

    /**
     * The raw MailHog search result for messages to {@code address}, after giving a mail that Keycloak might have
     * sent 3 s to arrive (it is delivered synchronously by the Admin API call, so this is generous).
     */
    private String mailsTo(String address) throws Exception {
        String mailhog = ConfigProvider.getConfig().getValue(KeycloakContainerResource.MAILHOG_URL, String.class);
        HttpClient http = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder(URI.create(mailhog + "/api/v2/search?kind=to&query="
                + URLEncoder.encode(address, StandardCharsets.UTF_8))).timeout(Duration.ofSeconds(5)).build();
        Thread.sleep(3_000);
        return http.send(request, HttpResponse.BodyHandlers.ofString()).body();
    }

    /** The token endpoint's raw answer to a password grant of the test-only direct-grant client. */
    private static String directGrant(String username, String password) throws Exception {
        String url = ConfigProvider.getConfig().getValue(KeycloakContainerResource.TOKEN_URL, String.class);
        String form = "grant_type=password&client_id=" + KeycloakContainerResource.DIRECT_GRANT_CLIENT
                + "&username=" + URLEncoder.encode(username, StandardCharsets.UTF_8)
                + "&password=" + URLEncoder.encode(password, StandardCharsets.UTF_8);
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form)).build();
        return HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString()).body();
    }
}
