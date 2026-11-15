package com.hoopsacademy.game.application;

import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Optional;

/** The academy's name as core published it (printed on the match sheet, WP117). */
public interface AcademyNames {

    /** @return the name, empty when game does not know it (never a failure: the caller prints a fallback) */
    Optional<String> find(TenantId tenantId);
}
