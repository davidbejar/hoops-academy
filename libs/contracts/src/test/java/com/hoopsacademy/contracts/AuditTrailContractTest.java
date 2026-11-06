package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.parameters.Parameter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * WP34 / ADR-0029: the audit trail ({@code core.audit_event}, ADR-0017) is readable by an academy's ADMIN
 * ({@code GET /api/core/audit-events}) and by the super admin across academies ({@code GET /platform/audit-events}).
 * The action names are published as one enum; core-service checks that it equals its own {@code AuditAction}.
 */
class AuditTrailContractTest {

    private static final OpenAPI CORE = OpenApiSpecs.parse("core").getOpenAPI();
    private static final OpenAPI RESOLVED = OpenApiSpecs.parseFullyResolved("core");

    @Test
    void coreIsVersion260() {
        assertThat(CORE.getInfo().getVersion()).isEqualTo("2.6.0");
    }

    @Test
    void theActionsAreOneEnumIncludingTheFirstSignIn() {
        Schema<?> action = schema("AuditAction");

        assertThat(action.getType()).isEqualTo("string");
        List<String> values = action.getEnum().stream().map(String::valueOf).toList();
        assertThat(values).doesNotHaveDuplicates().hasSize(28)
                .contains("member.invited", "member.invitation_accepted", "member.temporary_password_expired",
                        "player.approved", "player.rejected", "tenant.suspended", "admin.added");
        assertThat(values).allMatch(value -> value.matches("[a-z_]+\\.[a-z_]+"));
    }

    @Test
    void theTargetTypesAreAnEnum() {
        assertThat(schema("AuditTargetType").getEnum()).map(String::valueOf)
                .containsExactlyInAnyOrder("person", "player", "tenant", "approval_request", "guardian_link");
    }

    @Test
    void anEventNamesItsActorAndTargetWithResolvedNames() {
        Schema<?> event = schema("AuditEvent");
        assertThat(event.getRequired()).containsExactlyInAnyOrder("id", "at", "action", "actor", "target", "metadata");
        assertThat(property(event, "action").get$ref()).isEqualTo("#/components/schemas/AuditAction");
        assertThat(property(event, "metadata").getType()).isEqualTo("object");

        Schema<?> actor = schema("AuditActor");
        assertThat(actor.getRequired()).containsExactlyInAnyOrder("kind", "subject");
        assertThat(property(actor, "subject").getNullable()).isTrue();
        assertThat(property(actor, "subject").getDescription())
                .contains("null when the actor is masked for the caller (platform actors seen from an academy)");
        assertThat(property(actor, "personId").getNullable()).isTrue();
        assertThat(property(actor, "displayName").getNullable()).isTrue();
        assertThat(schema("AuditActorKind").getEnum()).map(String::valueOf)
                .containsExactly("PERSON", "PLATFORM", "SYSTEM");

        Schema<?> target = schema("AuditTarget");
        assertThat(target.getRequired()).containsExactlyInAnyOrder("type", "id");
        assertThat(property(target, "displayName").getNullable()).isTrue();
    }

    @Test
    void theAcademyListMasksPlatformActors() {
        // WP38, decision 16 of 2026-11-06: academy ADMINs read the reason, not who the super admin is
        assertThat(operation("listAuditEvents").getDescription()).contains("Platform administrator");
    }

    @Test
    void thePlatformEventAlsoNamesTheAcademy() {
        Schema<?> event = schema("PlatformAuditEvent");
        assertThat(event.getExtensions()).containsEntry("x-extends", List.of("AuditEvent"));
        assertThat(event.getRequired()).contains("tenantId", "tenantName");
        assertThat(property(event, "tenantId").getFormat()).isEqualTo("uuid");
    }

    @ParameterizedTest
    @ValueSource(strings = {"listAuditEvents", "listPlatformAuditEvents"})
    void bothListsFilterByTimeAndOneOrSeveralActionsAndArePaged(String operationId) {
        Operation operation = operation(operationId);
        Map<String, Parameter> parameters = operation.getParameters().stream()
                .collect(Collectors.toMap(Parameter::getName, p -> p));

        assertThat(parameters).containsKeys("from", "to", "action", "page", "size");
        assertThat(parameters.get("from").getSchema().getFormat()).isEqualTo("date-time");
        assertThat(parameters.get("to").getSchema().getFormat()).isEqualTo("date-time");
        Parameter action = parameters.get("action");
        assertThat(action.getSchema().getType()).isEqualTo("array");
        assertThat(action.getExplode()).isTrue();
        assertThat(action.getSchema().getItems().getEnum()).hasSize(28);
        assertThat(operation.getResponses()).containsKeys("200", "400", "401", "403", "404");
        assertThat(operation.getDescription()).contains("Authz:").containsIgnoringCase("retention");
    }

    @Test
    void theAcademyListIsForAdminsOfTheAcademy() {
        Operation operation = operation("listAuditEvents");
        assertThat(operation.getParameters()).extracting(Parameter::getName).contains("X-Tenant-Id");
        assertThat(operation.getDescription()).contains("Authz: ADMIN");
        assertThat(CORE.getPaths()).containsKey("/api/core/audit-events");
    }

    @Test
    void thePlatformListMayNarrowToOneAcademy() {
        Operation operation = operation("listPlatformAuditEvents");
        Parameter tenant = operation.getParameters().stream().filter(p -> "tenantId".equals(p.getName()))
                .findFirst().orElseThrow();
        assertThat(tenant.getIn()).isEqualTo("query");
        assertThat(tenant.getRequired()).isNotEqualTo(Boolean.TRUE);
        assertThat(tenant.getSchema().getFormat()).isEqualTo("uuid");
        assertThat(operation.getDescription()).contains("Authz: super_admin");
        assertThat(CORE.getPaths()).containsKey("/platform/audit-events");
    }

    private static Schema<?> schema(String name) {
        Schema<?> schema = CORE.getComponents().getSchemas().get(name);
        assertThat(schema).as(name).isNotNull();
        return schema;
    }

    private static Schema<?> property(Schema<?> schema, String name) {
        Schema<?> property = schema.getProperties().get(name);
        assertThat(property).as(name).isNotNull();
        return property;
    }

    private static Operation operation(String operationId) {
        return RESOLVED.getPaths().values().stream()
                .flatMap(item -> item.readOperations().stream())
                .filter(operation -> operationId.equals(operation.getOperationId()))
                .findFirst().orElseThrow(() -> new AssertionError("no operation " + operationId));
    }
}
