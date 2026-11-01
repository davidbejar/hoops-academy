package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Runs a {@code @QuarkusTest} method (or every method of a class) as an authenticated user who is a member of
 * {@link #tenant()} with the given roles and relations. Composes {@link TestSecurity} + {@link OidcSecurity}
 * (JWT {@code sub} = {@link #SUBJECT}) and registers the matching {@code AuthzContext} for
 * {@link TestAuthzContextResolver}. Any other tenant is "not a member" → 404.
 *
 * <pre>{@code
 * @Test
 * @TenantUser(tenant = TENANT_A, roles = TenantRole.COACH, staffTeams = TEAM_1)
 * void coachSeesOwnTeam() { given().header("X-Tenant-Id", TENANT_A).get("/api/core/teams/" + TEAM_1)... }
 * }</pre>
 */
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
@TestSecurity(user = TenantUser.SUBJECT)
@OidcSecurity(claims = @Claim(key = "sub", value = TenantUser.SUBJECT))
public @interface TenantUser {

    /** OIDC subject of the simulated caller. */
    String SUBJECT = "tenant-user";

    /** Tenant id (canonical UUID) the caller is a member of. */
    String tenant();

    TenantRole[] roles() default {};

    /** Person id (UUID); a fixed per-tenant default is derived when blank. */
    String personId() default "";

    /** Team ids (UUID) the caller is staff of. */
    String[] staffTeams() default {};

    /** Player ids (UUID) the caller is guardian of. */
    String[] linkedPlayers() default {};

    /** The caller's own player id (UUID), blank when not a player. */
    String ownPlayer() default "";
}
