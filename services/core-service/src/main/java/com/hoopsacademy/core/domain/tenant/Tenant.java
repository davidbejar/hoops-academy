package com.hoopsacademy.core.domain.tenant;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import com.hoopsacademy.core.domain.shared.Require;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.time.ZoneId;
import java.time.ZoneOffset;

/** A tenant (academy) as the platform sees it: master data and lifecycle. Immutable; transitions return copies. */
public record Tenant(
        TenantId id,
        TenantSlug slug,
        String name,
        TenantStatus status,
        String statusReason,
        ZoneId timezone,
        AppLocale defaultLocale,
        Instant createdAt,
        Instant suspendedAt,
        Instant withdrawnAt,
        LocalDate retainUntil) {

    static final int MAX_NAME = 120;

    public Tenant {
        name = Require.text(name, "name", MAX_NAME);
        Require.present(timezone, "timezone");
        Require.present(defaultLocale, "defaultLocale");
    }

    public static Tenant onboard(TenantId id, TenantSlug slug, String name, ZoneId timezone, AppLocale locale,
            Instant now) {
        return new Tenant(id, slug, name, TenantStatus.ACTIVE, null, timezone, locale, now, null, null, null);
    }

    public boolean isActive() {
        return status == TenantStatus.ACTIVE;
    }

    public Tenant suspend(String reason, Instant now) {
        requireStatus(TenantStatus.ACTIVE, "TENANT_NOT_ACTIVE");
        return new Tenant(id, slug, name, TenantStatus.SUSPENDED, reason, timezone, defaultLocale, createdAt, now,
                null, null);
    }

    public Tenant reactivate() {
        requireStatus(TenantStatus.SUSPENDED, "TENANT_NOT_SUSPENDED");
        return new Tenant(id, slug, name, TenantStatus.ACTIVE, null, timezone, defaultLocale, createdAt, null, null,
                null);
    }

    /** Terminal: data is retained for {@code retention} after withdrawal (purge job is v2). */
    public Tenant withdraw(String reason, Instant now, Period retention) {
        if (status == TenantStatus.WITHDRAWN) {
            throw new ConflictException("Tenant is already withdrawn", "TENANT_WITHDRAWN");
        }
        LocalDate retainUntil = LocalDate.ofInstant(now, ZoneOffset.UTC).plus(retention);
        return new Tenant(id, slug, name, TenantStatus.WITHDRAWN, reason, timezone, defaultLocale, createdAt,
                suspendedAt, now, retainUntil);
    }

    /** Whether the platform may still manage the tenant's administrators: ACTIVE and SUSPENDED yes, WITHDRAWN no. */
    public void requireManageable() {
        if (status == TenantStatus.WITHDRAWN) {
            throw new ConflictException("The academy is withdrawn; its administrators can no longer be changed",
                    "TENANT_WITHDRAWN");
        }
    }

    public Tenant changeMasterData(Patch<String> newName, Patch<ZoneId> newTimezone, Patch<AppLocale> newLocale) {
        return new Tenant(id, slug, newName.applyTo(name), status, statusReason, newTimezone.applyTo(timezone),
                newLocale.applyTo(defaultLocale), createdAt, suspendedAt, withdrawnAt, retainUntil);
    }

    private void requireStatus(TenantStatus expected, String code) {
        if (status != expected) {
            throw new ConflictException("Tenant is " + status + ", expected " + expected, code);
        }
    }
}
