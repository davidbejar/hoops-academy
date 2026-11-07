package com.hoopsacademy.common.security;

import io.quarkus.security.identity.SecurityIdentity;
import java.util.Set;
import org.eclipse.microprofile.jwt.JsonWebToken;

/**
 * Who a security event is about, as far as it is known.
 *
 * @param tenantId the requested or bound tenant, null when none
 * @param subject  the verified caller's {@code sub} (the principal name for non-JWT identities), null when anonymous
 * @param roles    tenant roles, or realm roles where no tenant applies
 */
public record SecurityCaller(String tenantId, String subject, Set<String> roles) {

    /** Nothing known (no request, an unverified token). */
    public static final SecurityCaller UNKNOWN = new SecurityCaller(null, null, Set.of());

    public SecurityCaller {
        roles = roles == null ? Set.of() : Set.copyOf(roles);
    }

    /**
     * The {@code sub} of a verified identity without ever failing (unlike {@code CallerSubject}): the principal name
     * when there is no {@code sub}, null for an anonymous or missing identity.
     */
    public static String subjectOf(SecurityIdentity identity) {
        if (identity == null || identity.isAnonymous() || identity.getPrincipal() == null) {
            return null;
        }
        if (identity.getPrincipal() instanceof JsonWebToken jwt && jwt.getSubject() != null && !jwt.getSubject().isBlank()) {
            return jwt.getSubject();
        }
        return identity.getPrincipal().getName();
    }
}
