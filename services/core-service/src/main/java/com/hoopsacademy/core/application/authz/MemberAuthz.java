package com.hoopsacademy.core.application.authz;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.core.domain.tenant.TenantStatus;

/** A caller's authorization context in a tenant plus that tenant's lifecycle status. */
public record MemberAuthz(AuthzContext context, TenantStatus tenantStatus) {

    public boolean tenantActive() {
        return tenantStatus == TenantStatus.ACTIVE;
    }
}
