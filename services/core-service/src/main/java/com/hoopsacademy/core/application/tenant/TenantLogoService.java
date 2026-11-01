package com.hoopsacademy.core.application.tenant;

import java.util.Map;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.LogoRepository;
import com.hoopsacademy.core.application.port.LogoRepository.StoredLogo;
import com.hoopsacademy.core.domain.logo.LogoImage;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;

/** Upload (validated by {@link LogoImage}), download and removal of the bound tenant's logo. */
@ApplicationScoped
public class TenantLogoService {

    private final LogoRepository logos;
    private final Clock clock;
    private final AuditLog audit;
    private final TenantContext tenantContext;

    public TenantLogoService(LogoRepository logos, Clock clock, AuditLog audit, TenantContext tenantContext) {
        this.logos = logos;
        this.clock = clock;
        this.audit = audit;
        this.tenantContext = tenantContext;
    }

    @Transactional
    public StoredLogo upload(byte[] content) {
        LogoImage image = LogoImage.of(content);
        StoredLogo stored = logos.save(image, clock.instant());
        audit.record(AuditEvent.of("tenant.logo_replaced", "tenant", tenantContext.requireTenantId(),
                Map.of("contentType", image.format().mediaType(), "sizeBytes", content.length)));
        return stored;
    }

    @Transactional
    public StoredLogo get() {
        return logos.find().orElseThrow(() -> new NotFoundException("No logo stored"));
    }

    @Transactional
    public void delete() {
        if (!logos.delete()) {
            throw new NotFoundException("No logo stored");
        }
        audit.record(AuditEvent.of("tenant.logo_removed", "tenant", tenantContext.requireTenantId()));
    }
}
