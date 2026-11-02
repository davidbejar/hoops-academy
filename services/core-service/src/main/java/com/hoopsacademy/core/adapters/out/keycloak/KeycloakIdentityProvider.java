package com.hoopsacademy.core.adapters.out.keycloak;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.LoginUpdate;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.keycloak.admin.client.CreatedResponseUtil;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.UserResource;
import org.keycloak.admin.client.resource.UsersResource;
import org.keycloak.representations.idm.CredentialRepresentation;
import org.keycloak.representations.idm.UserRepresentation;

/**
 * Keycloak Admin API through the service account of client {@code core-service} (needs realm-management
 * {@code manage-users}). Users are created enabled, without password, e-mail unverified; a created login is given a
 * temporary password by the caller (ADR-0024). Nothing here sends e-mail.
 */
@ApplicationScoped
class KeycloakIdentityProvider implements IdentityProviderPort {

    static final String EMAIL_TAKEN = "EMAIL_TAKEN";
    static final String UPDATE_PASSWORD = "UPDATE_PASSWORD";

    private final Keycloak keycloak;
    private final String realm;

    KeycloakIdentityProvider(Keycloak keycloak,
            @ConfigProperty(name = "hoops.keycloak.realm", defaultValue = "academy") String realm) {
        this.keycloak = keycloak;
        this.realm = realm;
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
    public void setTemporaryPassword(String subject, TemporaryPassword password) {
        CredentialRepresentation credential = new CredentialRepresentation();
        credential.setType(CredentialRepresentation.PASSWORD);
        credential.setTemporary(true);
        credential.setValue(password.reveal());
        call("set a temporary password", () -> {
            users().get(subject).resetPassword(credential);
            return null;
        });
    }

    @Override
    public boolean hasOwnPassword(String subject) {
        return call("read the credentials of the user", () -> {
            UserResource user = users().get(subject);
            boolean password = user.credentials().stream()
                    .anyMatch(credential -> CredentialRepresentation.PASSWORD.equals(credential.getType()));
            List<String> pending = user.toRepresentation().getRequiredActions();
            return password && (pending == null || !pending.contains(UPDATE_PASSWORD));
        });
    }

    @Override
    public void updateLogin(LoginUpdate update) {
        call("update login", () -> {
            UserResource user = users().get(update.subject());
            UserRepresentation moved = user.toRepresentation();
            moved.setUsername(update.email());
            moved.setEmail(update.email());
            moved.setFirstName(update.givenName());
            moved.setLastName(update.familyName());
            moved.setEmailVerified(false);
            updateOrConflict(user, moved);
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
