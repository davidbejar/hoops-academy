package com.hoopsacademy.core.application.port;

/**
 * Keycloak Admin API, used for user provisioning only (ADR-0005). Every method throws
 * {@link IdentityProviderException} when the provider fails or is unreachable.
 */
public interface IdentityProviderPort {

    /** Finds the login with this e-mail or creates it (enabled, e-mail unverified, no password). */
    ProvisionedIdentity provision(NewIdentity identity);

    /** Sends the execute-actions e-mail (UPDATE_PASSWORD, VERIFY_EMAIL). */
    void sendAccountSetupEmail(String subject);

    /** Compensation: removes a login this service created. Missing logins are ignored. */
    void delete(String subject);
}
