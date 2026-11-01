package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.common.tenancy.AuthzContext;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.jwt.JsonWebToken;

/**
 * The audit identity of the caller: their person in the tenant plus a display-name snapshot taken from the token
 * ({@code name}, then {@code preferred_username}), because this service does not own person data.
 */
@ApplicationScoped
class CallerActor {

    private static final String FALLBACK_NAME = "Member";

    private final SecurityIdentity identity;

    CallerActor(SecurityIdentity identity) {
        this.identity = identity;
    }

    Actor of(AuthzContext caller) {
        return new Actor(new PersonId(caller.personId()), displayName());
    }

    private String displayName() {
        if (identity.getPrincipal() instanceof JsonWebToken jwt) {
            for (String claim : new String[] {"name", "preferred_username"}) {
                Object value = jwt.getClaim(claim);
                if (value instanceof String text && !text.isBlank()) {
                    return text;
                }
            }
        }
        return FALLBACK_NAME;
    }
}
