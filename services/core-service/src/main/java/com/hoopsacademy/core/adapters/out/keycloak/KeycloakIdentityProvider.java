package com.hoopsacademy.core.adapters.out.keycloak;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.LoginUpdate;
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
import org.jboss.logging.Logger;
import org.keycloak.admin.client.CreatedResponseUtil;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.UserResource;
import org.keycloak.admin.client.resource.UsersResource;
import org.keycloak.representations.idm.UserRepresentation;

/**
 * Keycloak Admin API through the service account of client {@code core-service} (needs realm-management
 * {@code manage-users}). Users are created enabled, without password, e-mail unverified; the setup e-mail carries
 * the required actions.
 */
@ApplicationScoped
class KeycloakIdentityProvider implements IdentityProviderPort {

    static final String EMAIL_TAKEN = "EMAIL_TAKEN";

    static final List<String> SETUP_ACTIONS = List.of("UPDATE_PASSWORD", "VERIFY_EMAIL");
    static final List<String> VERIFY_ACTIONS = List.of("VERIFY_EMAIL");

    private static final Logger LOG = Logger.getLogger(KeycloakIdentityProvider.class);

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
    public void updateLogin(LoginUpdate update) {
        call("update login", () -> {
            UserResource user = users().get(update.subject());
            UserRepresentation previous = user.toRepresentation();
            UserRepresentation moved = user.toRepresentation();
            moved.setUsername(update.email());
            moved.setEmail(update.email());
            moved.setFirstName(update.givenName());
            moved.setLastName(update.familyName());
            moved.setEmailVerified(false);
            updateOrConflict(user, moved);
            try {
                user.executeActionsEmail(update.setupPending() ? SETUP_ACTIONS : VERIFY_ACTIONS,
                        setupEmailLifespanSeconds);
            } catch (RuntimeException mailFailure) {
                restore(user, previous, mailFailure);
                throw mailFailure;
            }
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

    private static void updateOrConflict(UserResource user, UserRepresentation changed) {
        try {
            user.update(changed);
        } catch (WebApplicationException e) {
            if (e.getResponse().getStatus() == Response.Status.CONFLICT.getStatusCode()) {
                throw new ConflictException("Another login already uses this e-mail", EMAIL_TAKEN);
            }
            throw e;
        }
    }

    /** Compensation of a failed mail: put the login back as it was (a failure here is logged and suppressed). */
    private static void restore(UserResource user, UserRepresentation previous, RuntimeException failure) {
        try {
            user.update(previous);
        } catch (RuntimeException restoreFailure) {
            failure.addSuppressed(restoreFailure);
            LOG.errorf("Could not restore Keycloak user %s after a failed e-mail; fix its username/e-mail manually",
                    previous.getId());
        }
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
