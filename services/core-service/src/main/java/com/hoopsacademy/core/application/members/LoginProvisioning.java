package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.function.Supplier;
import org.jboss.logging.Logger;

/**
 * The saga used by CreateTenant and InviteMember (two datasources + Keycloak, no distributed transaction):
 * 1. provision the login in Keycloak first (nothing written yet → a Keycloak failure leaves no trace);
 * 2. run the database work (the setup e-mail is its last step before commit);
 * 3. if the database work fails, delete the login — but only when step 1 created it.
 */
@ApplicationScoped
public class LoginProvisioning {

    private static final Logger LOG = Logger.getLogger(LoginProvisioning.class);

    private final IdentityProviderPort identityProvider;

    public LoginProvisioning(IdentityProviderPort identityProvider) {
        this.identityProvider = identityProvider;
    }

    public ProvisionedIdentity provision(NewIdentity identity) {
        return identityProvider.provision(identity);
    }

    public <T> T compensateOnFailure(ProvisionedIdentity login, Supplier<T> databaseWork) {
        try {
            return databaseWork.get();
        } catch (RuntimeException failure) {
            compensate(login, failure);
            throw failure;
        }
    }

    private void compensate(ProvisionedIdentity login, RuntimeException failure) {
        if (!login.created()) {
            return;
        }
        try {
            identityProvider.delete(login.subject());
        } catch (RuntimeException compensationFailure) {
            failure.addSuppressed(compensationFailure);
            LOG.errorf("Could not delete Keycloak user %s after a failed provisioning; delete it manually",
                    login.subject());
        }
    }
}
