package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import java.lang.module.ModuleDescriptor;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Invitation-only sign-up (WP90, ADR-0044, decisions 51 and 58): one public request operation that reveals nothing,
 * the super admin's list, accept and reject.
 */
class AcademyRequestContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parseFullyResolved("core");
    private static final String REQUESTS = "/platform/academy-requests";

    @SuppressWarnings("rawtypes")
    private static Map<String, Schema> schemas() {
        return OpenApiSpecs.parse("core").getOpenAPI().getComponents().getSchemas();
    }

    @Test
    void coreIsAtLeast330() {
        assertThat(ModuleDescriptor.Version.parse(CORE.getInfo().getVersion()))
                .isGreaterThanOrEqualTo(ModuleDescriptor.Version.parse("3.3.0"));
    }

    @Test
    void theRequestIsPublicAndAnswersTheSame202WhateverHappened() {
        Operation submit = CORE.getPaths().get(REQUESTS).getPost();

        assertThat(submit.getOperationId()).isEqualTo("submitAcademyRequest");
        assertThat(submit.getSecurity()).as("security: []").isNotNull().isEmpty();
        assertThat(submit.getResponses()).containsKeys("202", "409").doesNotContainKeys("200", "201");
        assertThat(submit.getDescription()).contains("ACADEMY_NAME_TAKEN", "honeypot", "Rate-limited", "202");
        Schema<?> received = submit.getResponses().get("202").getContent().get("application/json").getSchema();
        assertThat(received.getRequired()).containsExactly("status");
        assertThat(((Schema<?>) received.getProperties().get("status")).getEnum()).map(String::valueOf)
                .containsExactly("RECEIVED");
    }

    @Test
    void theFormCarriesNameEmailRoleAcademyAndAHoneypotWithBoundedLengths() {
        Schema<?> form = schemas().get("SubmitAcademyRequest");

        assertThat(form.getRequired()).containsExactlyInAnyOrder("email", "role", "academyName");
        assertThat(form.getProperties()).containsOnlyKeys("name", "email", "role", "academyName", "locale", "website");
        form.getProperties().forEach((name, property) -> {
            if (!name.equals("role") && !name.equals("locale")) {
                assertThat(((Schema<?>) property).getMaxLength()).as(name + " maxLength").isNotNull();
            }
        });
        assertThat(schemas().get("AcademyRequestRole").getEnum()).map(String::valueOf)
                .containsExactly("ADMIN", "COACH", "PARENT");
    }

    @Test
    void theSuperAdminListsAcceptsAndRejects() {
        assertThat(CORE.getPaths().get(REQUESTS).getGet().getOperationId()).isEqualTo("listAcademyRequests");
        Operation accept = CORE.getPaths().get(REQUESTS + "/{requestId}:accept").getPost();
        Operation reject = CORE.getPaths().get(REQUESTS + "/{requestId}:reject").getPost();

        assertThat(accept.getOperationId()).isEqualTo("acceptAcademyRequest");
        assertThat(accept.getResponses()).containsKeys("200", "409", "502");
        assertThat(accept.getDescription()).contains("REQUEST_NOT_PENDING", "SLUG_TAKEN", "ACADEMY_NAME_TAKEN",
                "tenant.request_accepted", "never the password");
        assertThat(reject.getOperationId()).isEqualTo("rejectAcademyRequest");
        assertThat(reject.getResponses()).containsKeys("200", "409");
        assertThat(schemas().get("RejectAcademyRequest").getRequired()).containsExactly("reason");
        for (Operation decision : new Operation[] {accept, reject, CORE.getPaths().get(REQUESTS).getGet()}) {
            assertThat(decision.getSecurity()).as(decision.getOperationId() + " uses the global bearer").isNull();
            assertThat(decision.getDescription()).contains("Authz: super_admin");
        }
    }

    @Test
    void theAuditTrailKnowsTheAcceptance() {
        assertThat(schemas().get("AuditAction").getEnum()).map(String::valueOf).contains("tenant.request_accepted");
    }
}
