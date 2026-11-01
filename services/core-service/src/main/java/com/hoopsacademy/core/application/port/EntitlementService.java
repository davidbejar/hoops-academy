package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;

/** Billing seam: may the tenant grow along {@code limit}? Throws a 409/422 domain exception when it may not. */
public interface EntitlementService {

    enum Limit {
        MEMBERS,
        PLAYERS,
        TEAMS
    }

    void check(TenantId tenant, Limit limit);
}
