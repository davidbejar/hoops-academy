package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.core.application.me.Caller;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import java.security.Principal;
import java.util.Optional;
import java.util.stream.Stream;
import org.eclipse.microprofile.jwt.JsonWebToken;

/** The caller taken from the validated access token (subject = JWT {@code sub}). */
@RequestScoped
public class CallerIdentity {

    public static final String SUPER_ADMIN = "super_admin";

    private final SecurityIdentity identity;

    public CallerIdentity(SecurityIdentity identity) {
        this.identity = identity;
    }

    public Caller current() {
        Principal principal = identity.getPrincipal();
        Optional<JsonWebToken> jwt = principal instanceof JsonWebToken token ? Optional.of(token) : Optional.empty();
        String subject = com.hoopsacademy.common.tenancy.CallerSubject.of(identity);
        String email = jwt.map(token -> token.<String>getClaim("email")).orElse(null);
        String displayName = Stream.of(claim(jwt, "name"), claim(jwt, "preferred_username"), email, subject)
                .filter(value -> value != null && !value.isBlank())
                .findFirst().orElse(subject);
        return new Caller(subject, identity.hasRole(SUPER_ADMIN), email, displayName);
    }

    private static String claim(Optional<JsonWebToken> jwt, String name) {
        return jwt.map(token -> token.<String>getClaim(name)).orElse(null);
    }
}
