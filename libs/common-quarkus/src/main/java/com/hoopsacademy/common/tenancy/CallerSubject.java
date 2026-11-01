package com.hoopsacademy.common.tenancy;

import io.quarkus.security.AuthenticationFailedException;
import io.quarkus.security.identity.SecurityIdentity;
import java.security.Principal;
import org.eclipse.microprofile.config.ConfigProvider;
import org.eclipse.microprofile.jwt.JsonWebToken;

/**
 * The stable caller id: the JWT {@code sub} claim. A JWT without {@code sub} (e.g. a Keycloak 25+ client missing the
 * {@code basic} scope) is rejected with 401 — never identified by {@code preferred_username}, which is mutable.
 * Non-JWT identities use the principal name. {@code hoops.security.require-sub=false} (set in the {@code %test}
 * profiles only, because {@code @TestSecurity} alone yields a JWT without claims) restores the principal-name fallback.
 */
public final class CallerSubject {

    private CallerSubject() {}

    public static String of(SecurityIdentity identity) {
        Principal principal = identity.getPrincipal();
        if (principal instanceof JsonWebToken jwt) {
            String subject = jwt.getSubject();
            if ((subject == null || subject.isBlank()) && !requireSub()) {
                return principal.getName();
            }
            if (subject == null || subject.isBlank()) {
                throw new AuthenticationFailedException("The access token carries no 'sub' claim");
            }
            return subject;
        }
        return principal.getName();
    }

    private static boolean requireSub() {
        return ConfigProvider.getConfig().getOptionalValue("hoops.security.require-sub", Boolean.class).orElse(true);
    }
}
