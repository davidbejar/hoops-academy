package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.logo.LogoImage;
import java.time.Instant;
import java.util.Optional;

/** Logo of the bound tenant (ADR-0009: bytea row; an object-storage adapter can implement the same port). */
public interface LogoRepository {

    record StoredLogo(LogoImage image, Instant updatedAt) {}

    Optional<StoredLogo> find();

    /** Metadata only (no bytes): whether a logo exists and its ETag. */
    Optional<String> findEtag();

    StoredLogo save(LogoImage image, Instant now);

    /** @return false when no logo was stored */
    boolean delete();
}
