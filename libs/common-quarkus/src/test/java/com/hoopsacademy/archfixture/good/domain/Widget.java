package com.hoopsacademy.archfixture.good.domain;

import com.hoopsacademy.common.tenancy.TenantId;

public record Widget(TenantId tenantId, String name) {}
