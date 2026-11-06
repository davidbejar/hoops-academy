package com.hoopsacademy.core.application.tenant;

import java.util.Map;
import com.hoopsacademy.core.application.shared.ChangedFields;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.LogoRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import com.hoopsacademy.core.domain.tenant.TenantProfileChanges;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

/** Academy profile of the bound tenant: any member reads, ADMIN edits (checked by the resource). */
@ApplicationScoped
public class TenantProfileService {

    private final TenantProfileRepository profiles;
    private final LogoRepository logos;
    private final AuditLog audit;
    private final TenantContext tenantContext;

    public TenantProfileService(TenantProfileRepository profiles, LogoRepository logos, AuditLog audit,
            TenantContext tenantContext) {
        this.profiles = profiles;
        this.logos = logos;
        this.audit = audit;
        this.tenantContext = tenantContext;
    }

    @Transactional
    public TenantProfileView get() {
        return new TenantProfileView(current(), logos.findEtag());
    }

    /** An edit that changes no stored value writes nothing (no audit row) and returns the profile as it is. */
    @Transactional
    public TenantProfileView update(TenantProfileChanges changes) {
        TenantProfile before = current();
        TenantProfile changed = before.apply(changes);
        ChangedFields fields = new ChangedFields().field("name", before.name(), changed.name())
                .field("timezone", before.timezone(), changed.timezone())
                .field("defaultLocale", before.defaultLocale(), changed.defaultLocale())
                .field("contactEmail", before.contactEmail(), changed.contactEmail())
                .field("websiteUrl", before.websiteUrl(), changed.websiteUrl());
        if (!fields.isEmpty()) {
            profiles.save(changed);
            audit.record(AuditEvent.of(AuditAction.TENANT_PROFILE_CHANGED, tenantContext.requireTenantId(),
                    Map.of("fields", fields.names())));
        }
        return new TenantProfileView(changed, logos.findEtag());
    }

    private TenantProfile current() {
        return profiles.findCurrent().orElseThrow(() -> new NotFoundException("Tenant not found"));
    }
}
