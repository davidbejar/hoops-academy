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

    /**
     * Moves the login to a new e-mail: username and e-mail = {@code update.email()}, names, e-mail unverified; then
     * mails the new address (VERIFY_EMAIL, or the setup actions while the invitation is pending). When that mail
     * fails, the previous login data is restored before the exception is thrown.
     *
     * @throws com.hoopsacademy.common.problem.ConflictException {@code EMAIL_TAKEN} when another login owns the e-mail
     */
    void updateLogin(LoginUpdate update);

    /** Compensation: removes a login this service created. Missing logins are ignored. */
    void delete(String subject);
}
