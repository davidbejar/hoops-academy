package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.media.Schema;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * WP32 / ADR-0028: a temporary password expires after a few days; members and administrators carry the state of their
 * login's temporary password so the consoles can label an expired one next to the re-issue action.
 */
class TemporaryPasswordExpiryContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parse("core").getOpenAPI();

    @Test
    void theStatusIsAnEnumOfActiveExpiredAndNone() {
        Schema<?> status = CORE.getComponents().getSchemas().get("TemporaryPasswordStatus");

        assertThat(status).isNotNull();
        assertThat(status.getType()).isEqualTo("string");
        assertThat(status.getEnum()).map(String::valueOf).containsExactly("ACTIVE", "EXPIRED", "NONE");
        assertThat(status.getDescription()).contains("EXPIRED").contains("ACTIVE").contains("NONE");
    }

    @ParameterizedTest
    @ValueSource(strings = {"Member", "TenantAdmin"})
    void membersAndAdministratorsAlwaysCarryTheStatus(String schemaName) {
        Schema<?> schema = CORE.getComponents().getSchemas().get(schemaName);

        assertThat(schema.getRequired()).as(schemaName).contains("temporaryPasswordStatus");
        assertThat(schema.getProperties().get("temporaryPasswordStatus").get$ref())
                .isEqualTo("#/components/schemas/TemporaryPasswordStatus");
    }

    @Test
    void theReissueOperationsSayTheyAlsoRenewAnExpiredPassword() {
        CORE.getPaths().values().stream()
                .flatMap(item -> item.readOperations().stream())
                .filter(operation -> "issueTenantAdminTemporaryPassword".equals(operation.getOperationId())
                        || "issueMemberTemporaryPassword".equals(operation.getOperationId()))
                .forEach(operation -> assertThat(operation.getDescription()).as(operation.getOperationId())
                        .containsIgnoringCase("expired"));
    }
}
