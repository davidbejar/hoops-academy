package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.port.LogoRepository.StoredLogo;
import java.time.Instant;

/** Contract {@code TenantLogo}. */
public record TenantLogoDto(String contentType, int sizeBytes, String etag, Instant updatedAt) {

    static TenantLogoDto of(StoredLogo logo) {
        return new TenantLogoDto(logo.image().format().mediaType(), logo.image().sizeBytes(), logo.image().etag(),
                logo.updatedAt());
    }
}
