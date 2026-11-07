package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.domain.signup.AcademyRequest;
import java.time.Instant;
import java.util.UUID;

/** Contract {@code AcademyRequest}. */
public record AcademyRequestDto(UUID id, String status, String name, String email, String role, String academyName,
        String locale, Instant requestedAt, Instant decidedAt, String decidedBy, String reason, UUID tenantId,
        Instant notifiedAt) {

    static AcademyRequestDto of(AcademyRequest request) {
        return new AcademyRequestDto(request.id().value(), request.status().name(),
                request.requester().name().orElse(null), request.requester().email(),
                request.requester().role().name(), request.academyName().value(), request.requester().locale().code(),
                request.requestedAt(), request.decidedAt(), request.decidedBy(), request.reason(),
                request.tenantId() == null ? null : request.tenantId().value(), request.notifiedAt());
    }
}
