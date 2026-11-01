package com.hoopsacademy.common.client;

import com.hoopsacademy.common.tenancy.AuthzContext;
import java.util.Objects;

/** A subject's membership as core reports it: the authorization context plus the tenant's lifecycle status. */
public record CoreMembership(AuthzContext context, TenantStatus tenantStatus) {

    public enum TenantStatus {
        ACTIVE,
        SUSPENDED,
        WITHDRAWN
    }

    public CoreMembership {
        Objects.requireNonNull(context, "context");
        Objects.requireNonNull(tenantStatus, "tenantStatus");
    }

    /** Members of a SUSPENDED or WITHDRAWN tenant are treated as non-members (404). */
    public boolean tenantActive() {
        return tenantStatus == TenantStatus.ACTIVE;
    }
}
