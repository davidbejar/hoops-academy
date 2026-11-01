package com.hoopsacademy.common.tenancy;

import io.quarkus.security.identity.SecurityIdentity;
import java.security.Principal;
import org.eclipse.microprofile.jwt.JsonWebToken;

/** The stable caller id: the JWT {@code sub} claim, or the principal name for non-JWT identities. */
final class CallerSubject {

    private CallerSubject() {}

    static String of(SecurityIdentity identity) {
        Principal principal = identity.getPrincipal();
        if (principal instanceof JsonWebToken jwt && jwt.getSubject() != null) {
            return jwt.getSubject();
        }
        return principal.getName();
    }
}
