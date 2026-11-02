package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.LoginUpdate;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.testsupport.KeycloakContainerResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
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
 * server. Run with {@code ./mvnw -pl services/core-service verify -Pkeycloak-it}.
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
    void updateLoginMovesUsernameAndEmailAndMailsTheNewAddress() throws Exception {
        String old = unique("old");
        ProvisionedIdentity login = identityProvider.provision(new NewIdentity(old, "Old", "Name", AppLocale.EN));
        String moved = unique("moved");

        identityProvider.updateLogin(new LoginUpdate(login.subject(), moved, "New", "Person", false));

        UserRepresentation stored = users().get(login.subject()).toRepresentation();
        assertThat(stored.getUsername()).isEqualTo(moved);
        assertThat(stored.getEmail()).isEqualTo(moved);
        assertThat(stored.getFirstName()).isEqualTo("New");
        assertThat(stored.getLastName()).isEqualTo("Person");
        assertThat(stored.isEmailVerified()).isFalse();
        assertThat(users().searchByEmail(old, true)).isEmpty();
        assertThat(users().searchByUsername(moved, true)).extracting(UserRepresentation::getId)
                .containsExactly(login.subject());
        assertThat(mailsTo(moved)).as("VERIFY_EMAIL mail to the new address").contains(moved);
        identityProvider.delete(login.subject());
    }

    @Test
    void anotherLoginsEmailIsAConflictAndChangesNothing() {
        String taken = unique("taken");
        ProvisionedIdentity owner = identityProvider.provision(new NewIdentity(taken, "Own", "Er", AppLocale.EN));
        String mine = unique("mine");
        ProvisionedIdentity login = identityProvider.provision(new NewIdentity(mine, "Me", "Too", AppLocale.EN));

        assertThatThrownBy(() -> identityProvider.updateLogin(
                new LoginUpdate(login.subject(), taken, "Me", "Too", false)))
                .isInstanceOf(ConflictException.class);
        assertThat(users().get(login.subject()).toRepresentation().getUsername()).isEqualTo(mine);
        identityProvider.delete(owner.subject());
        identityProvider.delete(login.subject());
    }

    @Test
    void aFailedMailRestoresThePreviousLogin() {
        String old = unique("restore");
        ProvisionedIdentity login = identityProvider.provision(new NewIdentity(old, "Re", "Store", AppLocale.EN));
        UserRepresentation disabled = users().get(login.subject()).toRepresentation();
        disabled.setEnabled(false); // Keycloak refuses execute-actions e-mails for disabled users
        users().get(login.subject()).update(disabled);

        assertThatThrownBy(() -> identityProvider.updateLogin(
                new LoginUpdate(login.subject(), unique("lost"), "Lo", "St", false)))
                .isInstanceOf(IdentityProviderException.class);
        UserRepresentation stored = users().get(login.subject()).toRepresentation();
        assertThat(stored.getUsername()).isEqualTo(old);
        assertThat(stored.getEmail()).isEqualTo(old);
        assertThat(stored.getFirstName()).isEqualTo("Re");
        identityProvider.delete(login.subject());
    }

    private UsersResource users() {
        return serviceAccount.realm("academy").users();
    }

    private static String unique(String prefix) {
        return prefix + "-" + UUID.randomUUID() + "@example.com";
    }

    /** The raw MailHog search result for messages to {@code address} (waits up to 10 s for delivery). */
    private String mailsTo(String address) throws Exception {
        String mailhog = ConfigProvider.getConfig().getValue(KeycloakContainerResource.MAILHOG_URL, String.class);
        HttpClient http = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder(
                URI.create(mailhog + "/api/v2/search?kind=to&query=" + address)).timeout(Duration.ofSeconds(5)).build();
        String body = "";
        for (int attempt = 0; attempt < 20; attempt++) {
            body = http.send(request, HttpResponse.BodyHandlers.ofString()).body();
            if (!body.contains("\"total\":0")) {
                return body;
            }
            Thread.sleep(500);
        }
        return body;
    }
}
