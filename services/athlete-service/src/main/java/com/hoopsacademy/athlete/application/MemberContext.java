package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import java.time.ZoneId;
import java.util.Optional;

/** The caller's membership as reported by core: authorization context, tenant lifecycle and (when core says) time zone. */
public record MemberContext(AuthzContext authz, TenantStatus tenantStatus, Optional<ZoneId> tenantZone) {}
