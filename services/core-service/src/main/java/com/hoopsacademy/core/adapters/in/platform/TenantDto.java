package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.domain.tenant.Tenant;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Contract {@code Tenant}. */
public record TenantDto(UUID id, String slug, String name, String status, String timezone, String defaultLocale,
        Instant createdAt, Instant suspendedAt, Instant withdrawnAt, LocalDate retainUntil) {

    static TenantDto of(Tenant tenant) {
        return new TenantDto(tenant.id().value(), tenant.slug().value(), tenant.name(), tenant.status().name(),
                tenant.timezone().getId(), tenant.defaultLocale().code(), tenant.createdAt(), tenant.suspendedAt(),
                tenant.withdrawnAt(), tenant.retainUntil());
    }
}
