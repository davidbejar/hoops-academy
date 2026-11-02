package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.testsupport.KeycloakContainerResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.representations.idm.UserRepresentation;

/**
 * The Keycloak adapter against a real Keycloak with the academy realm imported. Excluded from the default build
 * (surefire excludedGroups=keycloak); run with {@code ./mvnw -pl services/core-service verify -Pkeycloak-it}.
 */
@Tag("keycloak")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(KeycloakContainerResource.class)
class KeycloakIdentityProviderKeycloakTest {

    @Inject
    IdentityProviderPort identityProvider;

    @Inject
    Keycloak serviceAccount;

    @Test
    void createsFindsAndDeletesUsersWithTheServiceAccount() {
        String email = "kc-" + UUID.randomUUID() + "@example.com";
        ProvisionedIdentity created = identityProvider.provision(new NewIdentity(email, "Kc", "User", AppLocale.EN));
        assertThat(created.created()).isTrue();

        ProvisionedIdentity again = identityProvider.provision(new NewIdentity(email, "Kc", "User", AppLocale.EN));
        assertThat(again).isEqualTo(new ProvisionedIdentity(created.subject(), false));
        UserRepresentation stored = serviceAccount.realm("academy").users().get(created.subject()).toRepresentation();
        assertThat(stored.getEmail()).isEqualTo(email);
        assertThat(stored.isEnabled()).isTrue();
        assertThat(stored.isEmailVerified()).isFalse();
        assertThat(stored.getAttributes()).containsEntry("locale", List.of("en"));

        identityProvider.delete(created.subject());
        identityProvider.delete(created.subject());
        assertThat(serviceAccount.realm("academy").users().searchByEmail(email, true)).isEmpty();
    }
}
