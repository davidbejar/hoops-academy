package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleResponse;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.media.Schema;
import java.lang.module.ModuleDescriptor;
import java.util.Map;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Core 3.6.0 (WP106, decision 84): {@code /me} returns the caller's given and family name per membership, as that
 * academy stores the person, so the web's "Your name" form no longer splits the display name. Additive: the two
 * properties are optional in the schema (a client of 3.5 data still parses), core always sends them.
 */
class MeNamesContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parseFullyResolved("core");
    private static final String ME = "/api/core/me";
    private static final String MEMBERSHIP = """
            {"tenant": {"id": "0190b6a0-0000-7000-8000-0000000000aa", "slug": "hangtuah", "name": "Hangtuah",
                        "status": "ACTIVE", "hasLogo": false},
             "personId": "0190b6a0-0000-7000-8000-000000000002", %s"roles": ["COACH"],
             "authz": {"staffTeamIds": [], "historicStaffTeamIds": [], "linkedPlayerIds": [], "playerTeamIds": [],
                       "timezone": "Asia/Jakarta"}}""";

    private static OpenApiInteractionValidator strict;

    @BeforeAll
    static void strictValidator() {
        strict = OpenApiInteractionValidator.createForSpecificationUrl(ContractFiles.openApi("core").toUri().toString())
                .build();
    }

    @Test
    void coreIsAtLeast360() {
        assertThat(ModuleDescriptor.Version.parse(CORE.getInfo().getVersion()))
                .isGreaterThanOrEqualTo(ModuleDescriptor.Version.parse("3.6.0"));
    }

    @Test
    @SuppressWarnings("rawtypes")
    void eachMembershipCarriesTheGivenAndFamilyNameAdditively() {
        Schema<?> membership = OpenApiSpecs.parse("core").getOpenAPI().getComponents().getSchemas().get("Membership");
        Map<String, Schema> properties = membership.getProperties();

        assertThat(properties).containsKeys("givenName", "familyName");
        for (String name : new String[] {"givenName", "familyName"}) {
            Schema<?> property = properties.get(name);
            assertThat(property.getType()).as(name).isEqualTo("string");
            assertThat(property.getNullable()).as(name).isNotEqualTo(Boolean.TRUE);
            assertThat(property.getDescription()).as(name).contains("3.6.0");
        }
        assertThat(membership.getRequired()).as("additive: a 3.5 response still validates")
                .containsExactlyInAnyOrder("tenant", "personId", "roles", "authz")
                .doesNotContain("givenName", "familyName");
        assertThat(properties).as("no personal data beyond the name").doesNotContainKeys("email", "phone",
                "birthDate", "gender");
    }

    @Test
    void theStrictValidatorAcceptsTheNamesOnGetAndPatch() {
        String named = me(MEMBERSHIP.formatted("\"givenName\": \"Ana María\", \"familyName\": \"de la Cruz\", "));
        String unnamed = me(MEMBERSHIP.formatted(""));
        String nullName = me(MEMBERSHIP.formatted("\"givenName\": null, \"familyName\": \"Cruz\", "));

        assertThat(valid(named, Request.Method.GET)).isTrue();
        assertThat(valid(named, Request.Method.PATCH)).isTrue();
        assertThat(valid(unnamed, Request.Method.GET)).as("additive").isTrue();
        assertThat(valid(nullName, Request.Method.GET)).as("never null").isFalse();
    }

    private static String me(String membership) {
        return """
                {"userId": "0190b6a0-0000-7000-8000-000000000001", "sub": "kc-1", "email": null,
                 "displayName": "Ana María de la Cruz", "locale": "es", "superAdmin": false,
                 "memberships": [%s]}""".formatted(membership);
    }

    private static boolean valid(String body, Request.Method method) {
        return !strict.validateResponse(ME, method,
                SimpleResponse.Builder.ok().withContentType("application/json").withBody(body).build()).hasErrors();
    }
}
