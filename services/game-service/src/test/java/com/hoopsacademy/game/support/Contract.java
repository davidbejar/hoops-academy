package com.hoopsacademy.game.support;

import com.hoopsacademy.common.testing.ContractFilters;
import io.restassured.filter.Filter;

/**
 * Validates REST Assured exchanges against libs/contracts game.yaml, every MatchEvent included (common's
 * ContractFilters, strict), with the simulated bearer token so the contract's security requirement is checked too.
 */
public final class Contract {

    private static final ContractFilters SPEC = ContractFilters.forSpec("/openapi/game.yaml");

    /** Request and response must match the contract. */
    public static final Filter FILTER = ContractFilters.withSimulatedBearer(SPEC.strict());

    /**
     * Response validation only: for batches that send invalid events on purpose (the server rejects them per event,
     * libs/contracts README).
     */
    public static final Filter RESPONSES_ONLY = ContractFilters.withSimulatedBearer(SPEC.responsesOnly());

    private Contract() {}
}
