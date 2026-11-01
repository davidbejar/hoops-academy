package com.hoopsacademy.core.application.tenant;

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

    public TenantLogoService(LogoRepository logos, Clock clock) {
        this.logos = logos;
        this.clock = clock;
    }

    @Transactional
    public StoredLogo upload(byte[] content) {
        return logos.save(LogoImage.of(content), clock.instant());
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
    }
}
