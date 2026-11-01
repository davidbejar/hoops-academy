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
     * The contract composes schemas with allOf (e.g. TrainingSchedule = TrainingScheduleInput + id). The validator
     * checks each allOf member on its own and then reports the other members' properties as "additional", so this
     * one rule is ignored; types, required members, enums, formats and status/content types are still checked.
     */
    private static final LevelResolver ALLOF_FRIENDLY = LevelResolver.create()
            .withLevel("validation.response.body.schema.additionalProperties", ValidationReport.Level.IGNORE)
            .withLevel("validation.request.body.schema.additionalProperties", ValidationReport.Level.IGNORE)
            .build();
    private static final OpenApiInteractionValidator STRICT = OpenApiInteractionValidator
            .createForSpecificationUrl("/openapi/athlete.yaml").withLevelResolver(ALLOF_FRIENDLY).build();
    private static final OpenApiInteractionValidator RESPONSE_ONLY = OpenApiInteractionValidator
            .createForSpecificationUrl("/openapi/athlete.yaml")
            .withLevelResolver(LevelResolver.create()
                    .withLevel("validation.request", ValidationReport.Level.IGNORE)
                    .withLevel("validation.response.body.schema.additionalProperties", ValidationReport.Level.IGNORE)
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

    private static RequestSpecification base(String tenant) {
        return given().header("X-Tenant-Id", tenant).header("Authorization", "Bearer test").contentType(ContentType.JSON);
    }

    /** Registers the single test caller ({@code tenant-user}) as a member of {@code tenant}. */
    public static AuthzContext member(String tenant, Set<TenantRole> roles, Set<String> staffTeams, Set<String> linked,
            String ownPlayer) {
        AuthzContext context = new AuthzContext("tenant-user", UUID.nameUUIDFromBytes(("person-" + tenant).getBytes()),
                TenantId.parse(tenant), roles.isEmpty() ? Set.of() : EnumSet.copyOf(roles),
                uuids(staffTeams), uuids(linked), Optional.ofNullable(ownPlayer).map(UUID::fromString));
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
