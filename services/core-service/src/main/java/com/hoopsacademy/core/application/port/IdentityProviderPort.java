package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.identity.TemporaryPassword;

/**
 * Keycloak Admin API, used for user provisioning only (ADR-0005). Every method throws
 * {@link IdentityProviderException} when the provider fails or is unreachable. No method sends e-mail (ADR-0024).
 */
public interface IdentityProviderPort {

    /** Finds the login with this e-mail or creates it (enabled, e-mail unverified, no password). */
    ProvisionedIdentity provision(NewIdentity identity);

    /**
     * Replaces the login's password by {@code password} as a temporary credential: the next sign-in must choose a new
     * password (required action UPDATE_PASSWORD). The value never appears in an exception.
     */
    void setTemporaryPassword(String subject, TemporaryPassword password);

    /**
     * True when the person has chosen a password of their own: the login has a password credential and no pending
     * UPDATE_PASSWORD (a temporary password not used yet, or no password at all, is false).
     */
    boolean hasOwnPassword(String subject);

    /**
     * Moves the login to a new e-mail: username and e-mail = {@code update.email()} (unverified), names. Sends no
     * e-mail and leaves the password alone.
     *
     * @throws com.hoopsacademy.common.problem.ConflictException {@code EMAIL_TAKEN} when another login owns the e-mail
     */
    void updateLogin(LoginUpdate update);

    /**
     * Disables the login (an expired temporary password, ADR-0028): no sign-in and no token until {@link #enable}.
     * Changes nothing else about the login.
     */
    void disable(String subject);

    /** Enables a login {@link #disable} disabled (a new temporary password was issued). */
    void enable(String subject);

    /** Compensation: removes a login this service created. Missing logins are ignored. */
    void delete(String subject);
}
