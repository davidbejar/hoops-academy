package com.hoopsacademy.core.domain.tenant;

/** Lifecycle of a tenant: SUSPENDED blocks logins until reactivated; WITHDRAWN is terminal. */
public enum TenantStatus {
    ACTIVE,
    SUSPENDED,
    WITHDRAWN
}
