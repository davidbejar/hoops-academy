package com.hoopsacademy.common.security;

import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.security.spi.runtime.AuthenticationFailureEvent;
import io.quarkus.security.spi.runtime.AuthorizationFailureEvent;
import io.quarkus.security.spi.runtime.SecurityEvent;
import io.vertx.ext.web.RoutingContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;

/**
 * Turns the failures Quarkus Security reports itself into security events: bearer tokens Quarkus OIDC refuses
 * ({@link DenialKind#INVALID_TOKEN}) and the checks of {@code @Authenticated} / {@code @RolesAllowed}
 * ({@link DenialKind#UNAUTHENTICATED} for an anonymous caller, else {@link DenialKind#REALM_ROLE}). Tenant-level
 * denials are written where the tenancy layer decides them.
 */
@ApplicationScoped
public class QuarkusSecurityEvents {

    private final SecurityEventLog log;

    public QuarkusSecurityEvents(SecurityEventLog log) {
        this.log = log;
    }

    void authenticationFailed(@Observes AuthenticationFailureEvent event) {
        // the token was not verified: neither its subject nor any other claim is trusted or written
        log.denied(DenialKind.INVALID_TOKEN, SecurityCaller.UNKNOWN, request(event),
                TokenFailureReason.of(event.getAuthenticationFailure()));
    }

    void authorizationFailed(@Observes AuthorizationFailureEvent event) {
        SecurityIdentity identity = event.getSecurityIdentity();
        if (identity == null || identity.isAnonymous()) {
            log.denied(DenialKind.UNAUTHENTICATED, SecurityCaller.UNKNOWN, request(event), "no credentials");
            return;
        }
        log.denied(DenialKind.REALM_ROLE,
                new SecurityCaller(null, SecurityCaller.subjectOf(identity), identity.getRoles()),
                request(event), securedMethod(event));
    }

    private static RoutingContext request(SecurityEvent event) {
        return event.getEventProperties().get(RoutingContext.class.getName()) instanceof RoutingContext context
                ? context : null;
    }

    /** {@code Resource#method} of the refused method, without its package. */
    private static String securedMethod(AuthorizationFailureEvent event) {
        Object method = event.getEventProperties().get(AuthorizationFailureEvent.SECURED_METHOD_KEY);
        if (method == null) {
            return null;
        }
        String name = method.toString();
        int lastDot = name.lastIndexOf('.', name.indexOf('#') < 0 ? name.length() : name.indexOf('#'));
        return name.substring(lastDot + 1);
    }
}
