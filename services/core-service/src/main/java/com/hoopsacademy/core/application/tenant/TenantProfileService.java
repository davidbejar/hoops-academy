package com.hoopsacademy.core.application.tenant;

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

    public TenantProfileService(TenantProfileRepository profiles, LogoRepository logos) {
        this.profiles = profiles;
        this.logos = logos;
    }

    @Transactional
    public TenantProfileView get() {
        return new TenantProfileView(current(), logos.findEtag());
    }

    @Transactional
    public TenantProfileView update(TenantProfileChanges changes) {
        TenantProfile changed = current().apply(changes);
        profiles.save(changed);
        return new TenantProfileView(changed, logos.findEtag());
    }

    private TenantProfile current() {
        return profiles.findCurrent().orElseThrow(() -> new NotFoundException("Tenant not found"));
    }
}
