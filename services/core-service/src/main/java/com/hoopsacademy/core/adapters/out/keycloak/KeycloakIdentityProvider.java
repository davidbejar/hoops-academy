package com.hoopsacademy.core.adapters.out.keycloak;

import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.keycloak.admin.client.CreatedResponseUtil;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.UsersResource;
import org.keycloak.representations.idm.UserRepresentation;

/**
 * Keycloak Admin API through the service account of client {@code core-service} (needs realm-management
 * {@code manage-users}). Users are created enabled, without password, e-mail unverified; the setup e-mail carries
 * the required actions.
 */
@ApplicationScoped
class KeycloakIdentityProvider implements IdentityProviderPort {

    static final List<String> SETUP_ACTIONS = List.of("UPDATE_PASSWORD", "VERIFY_EMAIL");

    private final Keycloak keycloak;
    private final String realm;
    private final int setupEmailLifespanSeconds;

    KeycloakIdentityProvider(Keycloak keycloak,
            @ConfigProperty(name = "hoops.keycloak.realm", defaultValue = "academy") String realm,
            @ConfigProperty(name = "hoops.keycloak.setup-email-lifespan", defaultValue = "PT72H") Duration lifespan) {
        this.keycloak = keycloak;
        this.realm = realm;
        this.setupEmailLifespanSeconds = (int) lifespan.toSeconds();
    }

    @Override
    public ProvisionedIdentity provision(NewIdentity identity) {
        return call("provision user", () -> {
            List<UserRepresentation> existing = users().searchByEmail(identity.email(), true);
            if (!existing.isEmpty()) {
                return new ProvisionedIdentity(existing.get(0).getId(), false);
            }
            try (Response response = users().create(representationOf(identity))) {
                if (response.getStatus() != Response.Status.CREATED.getStatusCode()) {
                    throw new IdentityProviderException("Keycloak refused to create the user: HTTP " + response.getStatus());
                }
                return new ProvisionedIdentity(CreatedResponseUtil.getCreatedId(response), true);
            }
        });
    }

    @Override
    public void sendAccountSetupEmail(String subject) {
        call("send setup e-mail", () -> {
            users().get(subject).executeActionsEmail(SETUP_ACTIONS, setupEmailLifespanSeconds);
            return null;
        });
    }

    @Override
    public void delete(String subject) {
        call("delete user", () -> {
            try (Response response = users().delete(subject)) {
                int status = response.getStatus();
                if (status != Response.Status.NO_CONTENT.getStatusCode()
                        && status != Response.Status.NOT_FOUND.getStatusCode()) {
                    throw new IdentityProviderException("Keycloak refused to delete the user: HTTP " + status);
                }
            }
            return null;
        });
    }

    private UsersResource users() {
        return keycloak.realm(realm).users();
    }

    private static UserRepresentation representationOf(NewIdentity identity) {
        UserRepresentation user = new UserRepresentation();
        user.setUsername(identity.email());
        user.setEmail(identity.email());
        user.setFirstName(identity.givenName());
        user.setLastName(identity.familyName());
        user.setEnabled(true);
        user.setEmailVerified(false);
        if (identity.locale() != null) {
            user.setAttributes(Map.of("locale", List.of(identity.locale().code())));
        }
        return user;
    }

    private static <T> T call(String action, Supplier<T> request) {
        try {
            return request.get();
        } catch (IdentityProviderException e) {
            throw e;
        } catch (WebApplicationException | ProcessingException e) {
            throw new IdentityProviderException("Keycloak could not " + action, e);
        }
    }
}
