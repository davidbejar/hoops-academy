package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.responses.ApiResponse;
import java.lang.module.ModuleDescriptor;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * WP24 / ADR-0024: every operation that can create a login (or issue a new temporary password) returns the
 * server-generated temporary password once, read-only, never cached; the re-issue operations exist for the platform
 * and for academy admins.
 */
class TemporaryPasswordContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parseFullyResolved("core");

    @ParameterizedTest
    @CsvSource({
            "createTenant, 201",
            "addTenantAdmin, 200",
            "addTenantAdmin, 201",
            "issueTenantAdminTemporaryPassword, 200",
            "inviteMember, 201",
            "issueMemberTemporaryPassword, 200",
            "createPlayer, 201",
            "approveApprovalRequest, 200"})
    void responsesThatCanCarryATemporaryPasswordDeclareItReadOnlyAndUncached(String operationId, String status) {
        ApiResponse response = operation(operationId).getResponses().get(status);

        Schema<?> password = properties(response.getContent().get("application/json").getSchema())
                .get("temporaryPassword");
        assertThat(password).as(operationId + " " + status + " temporaryPassword").isNotNull();
        assertThat(password.getType()).isEqualTo("string");
        assertThat(password.getReadOnly()).isTrue();
        assertThat(password.getMinLength()).isGreaterThanOrEqualTo(12);
        assertThat(password.getDescription()).contains("once").contains("never stored");
        assertThat(response.getHeaders()).as(operationId + " " + status + " headers").containsKey("Cache-Control");
    }

    @ParameterizedTest
    @CsvSource({
            "issueTenantAdminTemporaryPassword, /platform/tenants/{tenantId}/admins/{personId}/temporary-password",
            "issueMemberTemporaryPassword, /api/core/members/{personId}/temporary-password"})
    void reissueOperationsAnswerConflictsAndKeycloakFailures(String operationId, String path) {
        Operation operation = operation(operationId);

        assertThat(CORE.getPaths().get(path).getPost()).as(path).isNotNull();
        assertThat(CORE.getPaths().get(path).getPost().getOperationId()).isEqualTo(operationId);
        assertThat(operation.getResponses()).containsKeys("200", "404", "409", "502");
        assertThat(operation.getDescription()).contains("INVITATION_NOT_PENDING");
    }

    /** ADR-0035: the deprecated {@code resendTenantAdminInvitation} alias (core 2.3.0) is removed in core 3.0.0. */
    @Test
    void theDeprecatedResendAliasIsRemovedInCore300() {
        assertThat(ModuleDescriptor.Version.parse(CORE.getInfo().getVersion()))
                .isGreaterThanOrEqualTo(ModuleDescriptor.Version.parse("3.0.0"));
        assertThat(CORE.getPaths())
                .doesNotContainKey("/platform/tenants/{tenantId}/admins/{personId}/resend-invitation");
        assertThat(CORE.getPaths().values().stream().flatMap(item -> item.readOperations().stream())
                .map(Operation::getOperationId)).doesNotContain("resendTenantAdminInvitation");
    }

    @Test
    void noOperationPromisesASetupOrVerificationEmailAnyMore() {
        CORE.getPaths().forEach((path, item) -> item.readOperations().forEach(operation ->
                assertThat(operation.getDescription() == null ? "" : operation.getDescription())
                        .as(operation.getOperationId())
                        .doesNotContainIgnoringCase("setup e-mail")
                        .doesNotContainIgnoringCase("account-setup")
                        .doesNotContainIgnoringCase("verification e-mail")
                        .doesNotContainIgnoringCase("required-action e-mail")
                        .doesNotContainIgnoringCase("invitation e-mail")));
    }

    private static Operation operation(String operationId) {
        return CORE.getPaths().values().stream()
                .flatMap(item -> item.readOperations().stream())
                .filter(op -> operationId.equals(op.getOperationId()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("core has no operation " + operationId));
    }

    /** The properties of a schema including those of its {@code allOf} parts (refs are already inlined). */
    @SuppressWarnings({"rawtypes", "unchecked"})
    private static Map<String, Schema> properties(Schema<?> schema) {
        Map<String, Schema> all = new LinkedHashMap<>();
        if (schema.getAllOf() != null) {
            for (Schema part : (List<Schema>) (List) schema.getAllOf()) {
                all.putAll(properties(part));
            }
        }
        if (schema.getProperties() != null) {
            all.putAll(schema.getProperties());
        }
        return all;
    }
}
