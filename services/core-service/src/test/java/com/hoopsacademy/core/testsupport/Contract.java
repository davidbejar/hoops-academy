package com.hoopsacademy.core.testsupport;

import static io.restassured.RestAssured.given;

import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import com.hoopsacademy.common.testing.ContractFilters;
import io.restassured.specification.RequestSpecification;

/** Validates every REST-assured exchange against {@code libs/contracts/openapi/core.yaml} (common's ContractFilters). */
public final class Contract {

    private static final ContractFilters SPEC = ContractFilters.forSpec("/openapi/core.yaml");

    /** Request AND response must match the contract. */
    public static final OpenApiValidationFilter CORE = SPEC.strict();

    /**
     * For negative tests that send a request the contract forbids on purpose (wrong media type, oversize body):
     * the request is not validated, the response still is.
     */
    public static final OpenApiValidationFilter RESPONSES_ONLY = SPEC.responsesOnly();

    /**
     * For fault-injection tests (simulated database failure → 500): a status no operation declares is tolerated,
     * everything else (request, Problem body, content type) is still validated. Declared failures such as 502
     * IDENTITY_PROVIDER_UNAVAILABLE use {@link #CORE}.
     */
    public static final OpenApiValidationFilter UNEXPECTED_FAILURE = SPEC.toleratingUndeclaredStatus();

    private Contract() {}

    /** A request in the academy {@code tenant} ({@code X-Tenant-Id}), validated against the contract ({@link #CORE}). */
    public static RequestSpecification forTenant(Object tenant) {
        return given().filter(CORE).header("X-Tenant-Id", tenant);
    }
}
