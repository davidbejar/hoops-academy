package com.hoopsacademy.common.security;

/** What kind of authentication or authorization failure a security event records, and the status the caller got. */
public enum DenialKind {

    /** No credentials on a path that needs them. */
    UNAUTHENTICATED("unauthenticated", 401),
    /** A bearer token Quarkus OIDC refused (expired, foreign audience, bad signature, malformed, no {@code sub}). */
    INVALID_TOKEN("invalid_token", 401),
    /** An authenticated caller who is no member of the requested tenant (answered 404, never 403). */
    NOT_MEMBER("not_member", 404),
    /** The membership resolved for the requested tenant belongs to another tenant: never bound, answered 404. */
    TENANT_MISMATCH("tenant_mismatch", 404),
    /** A member without any of the tenant roles of {@code @RequiresTenantRole}. */
    ROLE("role", 403),
    /** A member refused by a relation check ({@code Authz.require}, an {@code AccessDeniedException}). */
    FINE_GRAINED("fine_grained", 403),
    /** A caller without the realm role of {@code @RolesAllowed} ({@code super_admin} on /platform, {@code service}). */
    REALM_ROLE("realm_role", 403);

    private final String wireName;
    private final int status;

    DenialKind(String wireName, int status) {
        this.wireName = wireName;
        this.status = status;
    }

    /** The value of the event field {@code security.kind} and of the metric tag {@code kind}. */
    public String wireName() {
        return wireName;
    }

    /** The HTTP status the caller was answered. */
    public int status() {
        return status;
    }
}
