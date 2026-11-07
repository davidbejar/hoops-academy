package com.hoopsacademy.athlete.support;

import static io.restassured.RestAssured.given;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** REST Assured entry points that validate every exchange against {@code athlete.yaml}, plus membership helpers. */
public final class ApiSupport {

    /**
     * Default, strict configuration: the contract has no allOf compositions (StrictValidatorCompatibilityTest), so an
     * undeclared request or response field fails the test.
     */
    private static final OpenApiInteractionValidator STRICT = OpenApiInteractionValidator
            .createForSpecificationUrl("/openapi/athlete.yaml").build();
    private static final OpenApiInteractionValidator RESPONSE_ONLY = OpenApiInteractionValidator
            .createForSpecificationUrl("/openapi/athlete.yaml")
            .withLevelResolver(LevelResolver.create()
                    .withLevel("validation.request", ValidationReport.Level.IGNORE)
                    .build())
            .build();

    private ApiSupport() {}

    /** Request and response are validated against the contract. */
    public static RequestSpecification api(String tenant) {
        return base(tenant).filter(new OpenApiValidationFilter(STRICT));
    }

    /** For deliberately invalid requests: only the response is validated. */
    public static RequestSpecification lenient(String tenant) {
        return base(tenant).filter(new OpenApiValidationFilter(RESPONSE_ONLY));
    }

    /** No OpenAPI validation: role-matrix calls that only assert the status code. */
    public static RequestSpecification unvalidated(String tenant) {
        return base(tenant);
    }

    private static RequestSpecification base(String tenant) {
        return given().header("X-Tenant-Id", tenant).header("Authorization", "Bearer test").contentType(ContentType.JSON);
    }

    /** Registers the single test caller ({@code tenant-user}) as a member of {@code tenant}. */
    public static AuthzContext member(String tenant, Set<TenantRole> roles, Set<String> staffTeams, Set<String> linked,
            String ownPlayer) {
        return member(tenant, roles, staffTeams, linked, ownPlayer, Set.of());
    }

    /** As above, with the teams of the own / linked players ({@code AuthzContext.playerTeamIds}, from core). */
    public static AuthzContext member(String tenant, Set<TenantRole> roles, Set<String> staffTeams, Set<String> linked,
            String ownPlayer, Set<String> playerTeams) {
        AuthzContext context = new AuthzContext("tenant-user", UUID.nameUUIDFromBytes(("person-" + tenant).getBytes()),
                TenantId.parse(tenant), roles.isEmpty() ? Set.of() : EnumSet.copyOf(roles),
                uuids(staffTeams), uuids(linked), Optional.ofNullable(ownPlayer).map(UUID::fromString), uuids(playerTeams),
                Optional.empty());
        TenantUserRegistry.register(context);
        return context;
    }

    /** A coach of {@code staffTeams} today who was staff of {@code historicTeams} in seasons that have ended. */
    public static AuthzContext formerStaff(String tenant, TenantRole role, Set<String> staffTeams,
            Set<String> historicTeams) {
        AuthzContext context = member(tenant, Set.of(role), staffTeams, Set.of(), null)
                .withHistoricStaffTeamIds(uuids(historicTeams));
        TenantUserRegistry.register(context);
        return context;
    }

    public static AuthzContext member(String tenant, TenantRole... roles) {
        return member(tenant, Set.of(roles), Set.of(), Set.of(), null);
    }

    private static Set<UUID> uuids(Set<String> raw) {
        return raw.stream().map(UUID::fromString).collect(java.util.stream.Collectors.toSet());
    }
}
