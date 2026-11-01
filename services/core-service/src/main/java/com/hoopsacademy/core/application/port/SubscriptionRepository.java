package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;

/** Billing seam: every tenant starts on a plan (v1: FREE, unlimited). Platform datasource. */
public interface SubscriptionRepository {

    String DEFAULT_PLAN = "FREE";

    void subscribe(TenantId tenant, String planCode);

    void deleteUnprovisioned(TenantId tenant);
}
