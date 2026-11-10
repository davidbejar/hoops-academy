package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.atlassian.oai.validator.model.SimpleResponse;
import com.atlassian.oai.validator.report.ValidationReport;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.parameters.Parameter;
import java.lang.module.ModuleDescriptor;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Core 3.4.0 (WP91): the super admin's Users area reads every login with its memberships across academies (decision
 * 71), and a member changes their own first and last name through {@code PATCH /api/core/me} (decision 73).
 */
class PlatformUsersContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parseFullyResolved("core");
    private static final String USERS = "/platform/users";
    private static final String ME = "/api/core/me";
    private static final String TENANT = "0190b6a0-0000-7000-8000-0000000000aa";

    private static OpenApiInteractionValidator strict;

    @BeforeAll
    static void strictValidator() {
        strict = OpenApiInteractionValidator.createForSpecificationUrl(ContractFiles.openApi("core").toUri().toString())
                .build();
    }

    @SuppressWarnings("rawtypes")
    private static Map<String, Schema> schemas() {
        return OpenApiSpecs.parse("core").getOpenAPI().getComponents().getSchemas();
    }

    @Test
    void coreIsAtLeast340() {
        assertThat(ModuleDescriptor.Version.parse(CORE.getInfo().getVersion()))
                .isGreaterThanOrEqualTo(ModuleDescriptor.Version.parse("3.4.0"));
    }

    @Test
    void theUserListIsAPagedSearchForTheSuperAdminOnly() {
        Operation list = CORE.getPaths().get(USERS).getGet();

        assertThat(list.getOperationId()).isEqualTo("listPlatformUsers");
        assertThat(list.getTags()).containsExactly("Platform");
        assertThat(list.getSecurity()).as("the global bearer").isNull();
        assertThat(list.getDescription()).contains("Authz: super_admin").containsIgnoringCase("read-only")
                .contains("audit");
        assertThat(CORE.getPaths().get(USERS).readOperations()).as("read-only this round").hasSize(1);
        Map<String, Parameter> parameters = list.getParameters().stream()
                .collect(Collectors.toMap(Parameter::getName, p -> p));
        assertThat(parameters).containsOnlyKeys("q", "page", "size");
        Schema<?> q = parameters.get("q").getSchema();
        assertThat(q.getMinLength()).isEqualTo(2);
        assertThat(q.getMaxLength()).isEqualTo(100);
        assertThat(parameters.get("q").getRequired()).isNotEqualTo(Boolean.TRUE);
        assertThat(list.getResponses()).containsKeys("200", "400", "401", "403", "404");
    }

    @Test
    void eachLoginCarriesItsMembershipsPerAcademy() {
        Schema<?> user = schemas().get("PlatformUser");
        assertThat(user.getRequired()).containsExactlyInAnyOrder("id", "createdAt", "memberships");
        assertThat(user.getProperties()).containsOnlyKeys("id", "email", "createdAt", "memberships");
        assertThat(((Schema<?>) user.getProperties().get("email")).getNullable()).isTrue();

        Schema<?> membership = schemas().get("PlatformUserMembership");
        assertThat(membership.getRequired()).containsExactlyInAnyOrder("tenantId", "tenantName", "tenantSlug",
                "tenantStatus", "personId", "givenName", "familyName", "roles", "active");
        assertThat(membership.getProperties()).as("no personal data beyond the name")
                .doesNotContainKeys("birthDate", "phone", "gender", "email");
        assertThat(schemas().get("PlatformUserPage").getRequired()).containsExactlyInAnyOrder("items", "page");
    }

    @Test
    void theStrictValidatorAcceptsAPageAndRejectsAShortQuery() {
        String page = """
                {"items": [{"id": "0190b6a0-0000-7000-8000-000000000001", "email": "ada@example.com",
                  "createdAt": "2026-11-10T08:00:00Z",
                  "memberships": [{"tenantId": "%s", "tenantName": "Hangtuah", "tenantSlug": "hangtuah",
                    "tenantStatus": "ACTIVE", "personId": "0190b6a0-0000-7000-8000-000000000002",
                    "givenName": "Ada", "familyName": "Admin", "roles": ["ADMIN", "COACH"], "active": true}]},
                  {"id": "0190b6a0-0000-7000-8000-000000000003", "createdAt": "2026-11-10T08:00:00Z",
                   "memberships": []}],
                 "page": {"page": 0, "size": 50, "totalElements": 2, "totalPages": 1}}""".formatted(TENANT);

        assertThat(strict.validateResponse(USERS, Request.Method.GET,
                SimpleResponse.Builder.ok().withContentType("application/json").withBody(page).build())
                .hasErrors()).isFalse();
        assertThat(list("ad").hasErrors()).isFalse();
        assertThat(list("a").hasErrors()).as("at least 2 characters").isTrue();
    }

    private static ValidationReport list(String query) {
        return strict.validateRequest(SimpleRequest.Builder.get(USERS).withQueryParam("q", query)
                .withAuthorization("Bearer test").build());
    }

    @Test
    void aMemberChangesTheirOwnNameInOneAcademyButNeverTheEmail() {
        Schema<?> update = schemas().get("UpdateMeRequest");

        assertThat(update.getProperties()).containsOnlyKeys("locale", "givenName", "familyName", "tenantId");
        assertThat(update.getRequired()).as("every member optional").isNullOrEmpty();
        assertThat(update.getMinProperties()).isEqualTo(1);
        assertThat(update.getAdditionalProperties()).isEqualTo(false);
        Map<String, Schema> member = schemas().get("UpdateMemberRequest").getProperties();
        for (String name : List.of("givenName", "familyName")) {
            Schema<?> mine = (Schema<?>) update.getProperties().get(name);
            assertThat(mine.getMinLength()).as(name).isEqualTo(member.get(name).getMinLength());
            assertThat(mine.getMaxLength()).as(name).isEqualTo(member.get(name).getMaxLength());
            assertThat(mine.getNullable()).as(name).isNotEqualTo(Boolean.TRUE);
        }
        assertThat(((Schema<?>) update.getProperties().get("tenantId")).getFormat()).isEqualTo("uuid");
        assertThat(CORE.getPaths().get(ME).getPatch().getDescription()).contains("Authz:", "member.updated",
                "core.person");

        assertThat(patchMe("{\"locale\": \"en\"}").hasErrors()).isFalse();
        assertThat(patchMe("{\"givenName\": \"Ada\", \"familyName\": \"Lovelace\", \"tenantId\": \"" + TENANT + "\"}")
                .hasErrors()).isFalse();
        assertThat(patchMe("{\"email\": \"ada@example.com\"}").hasErrors()).as("the e-mail stays with the admin")
                .isTrue();
        assertThat(patchMe("{\"givenName\": \"\", \"tenantId\": \"" + TENANT + "\"}").hasErrors()).isTrue();
        assertThat(patchMe("{}").hasErrors()).isTrue();
    }

    private static ValidationReport patchMe(String body) {
        return strict.validateRequest(SimpleRequest.Builder.patch(ME).withContentType("application/json")
                .withAuthorization("Bearer test").withBody(body).build());
    }
}
