package com.hoopsacademy.contracts;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.PathItem;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.parameters.Parameter;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.parser.core.models.SwaggerParseResult;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.FieldSource;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/** Conventions every operation of every service contract must follow (see libs/contracts/README.md). */
class OpenApiConventionsTest {

    private static final List<String> SERVICES = OpenApiSpecs.SERVICES;
    private static final String PROBLEM_JSON = "application/problem+json";
    private static final Set<String> MANDATORY_ERROR_STATUSES = Set.of("400", "401", "403", "404");
    private static final String CAMEL_CASE = "^[a-z][a-zA-Z0-9]*$";

    /** One operation together with the path it belongs to. */
    private record Op(String service, String path, PathItem.HttpMethod method, PathItem pathItem, Operation operation) {

        String id() {
            return service + " " + method + " " + path;
        }

        List<Parameter> parameters() {
            return Stream.concat(
                            Objects.requireNonNullElse(pathItem.getParameters(), List.<Parameter>of()).stream(),
                            Objects.requireNonNullElse(operation.getParameters(), List.<Parameter>of()).stream())
                    .toList();
        }

        boolean isTenantScoped() {
            return path.startsWith("/api/") && !path.equals("/api/core/me");
        }
    }

    private static List<Op> operations(String service) {
        OpenAPI api = OpenApiSpecs.parseFullyResolved(service);
        List<Op> ops = new ArrayList<>();
        api.getPaths().forEach((path, item) -> item.readOperationsMap()
                .forEach((method, operation) -> ops.add(new Op(service, path, method, item, operation))));
        return ops;
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void specParsesWithoutMessages(String service) {
        SwaggerParseResult result = OpenApiSpecs.parse(service);

        assertThat(result.getMessages()).as(service + " parse messages").isEmpty();
        assertThat(result.getOpenAPI().getOpenapi()).isEqualTo("3.0.3");
        assertThat(result.getOpenAPI().getPaths()).isNotEmpty();
    }

    @Test
    void sharedComponentsParseWithoutMessages() {
        SwaggerParseResult result = OpenApiSpecs.parse("common");

        assertThat(result.getMessages()).isEmpty();
        assertThat(result.getOpenAPI().getComponents().getSchemas()).containsKeys("Problem", "PageMeta");
        assertThat(result.getOpenAPI().getComponents().getParameters()).containsKeys("TenantIdHeader", "Page", "Size");
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void globalSecurityIsBearerAuth(String service) {
        OpenAPI api = OpenApiSpecs.parseFullyResolved(service);

        assertThat(api.getSecurity()).hasSize(1);
        assertThat(api.getSecurity().getFirst()).containsOnlyKeys("bearerAuth");
        assertThat(api.getComponents().getSecuritySchemes()).containsKey("bearerAuth");
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void everyOperationHasCamelCaseUniqueIdTagsAndSummary(String service) {
        List<Op> ops = operations(service);
        Set<String> seen = new HashSet<>();

        assertThat(ops).isNotEmpty().allSatisfy(op -> {
            Operation operation = op.operation();
            assertThat(operation.getOperationId()).as(op.id() + " operationId").isNotBlank().matches(CAMEL_CASE);
            assertThat(seen.add(operation.getOperationId())).as(op.id() + " unique operationId").isTrue();
            assertThat(operation.getTags()).as(op.id() + " tags").isNotEmpty();
            assertThat(operation.getSummary()).as(op.id() + " summary").isNotBlank();
        });
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void everyOperationIsSecured(String service) {
        OpenAPI api = OpenApiSpecs.parseFullyResolved(service);

        assertThat(operations(service)).allSatisfy(op -> {
            var effective = op.operation().getSecurity() != null ? op.operation().getSecurity() : api.getSecurity();
            assertThat(effective).as(op.id() + " security").isNotEmpty();
            assertThat(effective).as(op.id() + " security must not be anonymous").noneMatch(Map::isEmpty);
        });
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void everyOperationDeclaresMandatoryProblemResponses(String service) {
        assertThat(operations(service)).allSatisfy(op ->
                assertThat(op.operation().getResponses()).as(op.id() + " responses")
                        .containsKeys(MANDATORY_ERROR_STATUSES.toArray(String[]::new)));
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void everyErrorResponseIsProblemJson(String service) {
        assertThat(operations(service)).allSatisfy(op -> op.operation().getResponses().forEach((status, response) -> {
            if (status.startsWith("4") || status.startsWith("5")) {
                assertThat(problemContent(response)).as(op.id() + " " + status + " content").isNotNull();
                Schema<?> problem = problemContent(response).get(PROBLEM_JSON).getSchema();
                List<String> required = problem.getRequired();
                assertThat(required)
                        .as(op.id() + " " + status + " Problem schema").contains("type", "title", "status");
            }
        }));
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void everySuccessResponseIsTyped(String service) {
        assertThat(operations(service)).allSatisfy(op -> op.operation().getResponses().forEach((status, response) -> {
            boolean hasBody = status.startsWith("2") && !status.equals("204");
            if (hasBody) {
                assertThat(response.getContent()).as(op.id() + " " + status + " content").isNotEmpty();
                response.getContent().forEach((mediaType, media) ->
                        assertThat(media.getSchema()).as(op.id() + " " + status + " " + mediaType).isNotNull());
            }
        }));
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void tenantScopedOperationsRequireTenantHeader(String service) {
        assertThat(operations(service)).filteredOn(Op::isTenantScoped).isNotEmpty().allSatisfy(op -> {
            Parameter header = tenantHeader(op);
            assertThat(header).as(op.id() + " declares " + ContractFiles.TENANT_HEADER).isNotNull();
            assertThat(header.getRequired()).as(op.id() + " tenant header required").isTrue();
            assertThat(header.getSchema().getFormat()).isEqualTo("uuid");
        });
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void platformInternalAndMeOperationsDoNotTakeTenantHeader(String service) {
        assertThat(operations(service)).filteredOn(op -> !op.isTenantScoped())
                .allSatisfy(op -> assertThat(tenantHeader(op)).as(op.id()).isNull());
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void pathsBelongToTheServiceFamilies(String service) {
        Function<String, Boolean> allowed = path -> path.startsWith("/api/" + service + "/")
                || path.startsWith("/internal/")
                || (service.equals("core") && path.startsWith("/platform/"));

        assertThat(operations(service)).allSatisfy(op -> assertThat(allowed.apply(op.path())).as(op.id()).isTrue());
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void internalOperationsAreTaggedAndHiddenFromClients(String service) {
        assertThat(operations(service)).filteredOn(op -> op.path().startsWith("/internal/")).isNotEmpty()
                .allSatisfy(op -> {
                    assertThat(op.operation().getTags()).as(op.id()).containsExactly("Internal");
                    assertThat(op.operation().getExtensions()).as(op.id() + " x-internal")
                            .containsEntry("x-internal", true);
                });
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void identifierPathParametersAreUuids(String service) {
        assertThat(operations(service)).allSatisfy(op -> op.parameters().stream()
                .filter(p -> "path".equals(p.getIn()) && !p.getName().equals("sub"))
                .forEach(p -> assertThat(p.getSchema().getFormat()).as(op.id() + " path param " + p.getName())
                        .isEqualTo("uuid")));
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void pageSizeIsCappedAt200(String service) {
        assertThat(operations(service)).allSatisfy(op -> op.parameters().stream()
                .filter(p -> "query".equals(p.getIn()) && p.getName().equals("size"))
                .forEach(p -> assertThat(p.getSchema().getMaximum()).as(op.id()).isEqualByComparingTo("200")));
    }

    private static Parameter tenantHeader(Op op) {
        return op.parameters().stream()
                .filter(p -> "header".equals(p.getIn()) && ContractFiles.TENANT_HEADER.equals(p.getName()))
                .findFirst()
                .orElse(null);
    }

    private static Content problemContent(ApiResponse response) {
        Content content = response.getContent();
        return content != null && content.containsKey(PROBLEM_JSON) ? content : null;
    }
}
