package com.hoopsacademy.core.domain.signup;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.shared.Require;
import java.time.Instant;
import java.util.Objects;

/**
 * A request for a new academy (decisions 51 and 58, ADR-0044). Immutable; a decision returns a copy. The decision
 * (who, when, the reason or the academy created) is the record of a rejection: no academy exists to hold an audit row.
 */
public record AcademyRequest(
        AcademyRequestId id,
        AcademyRequestStatus status,
        Requester requester,
        AcademyName academyName,
        Instant requestedAt,
        Instant decidedAt,
        String decidedBy,
        String reason,
        TenantId tenantId,
        Instant notifiedAt) {

    public static final int MAX_REASON = 500;

    public AcademyRequest {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(requester, "requester");
        Objects.requireNonNull(academyName, "academyName");
        Objects.requireNonNull(requestedAt, "requestedAt");
        boolean decided = decidedAt != null && decidedBy != null;
        boolean consistent = switch (status) {
            case PENDING -> decidedAt == null && decidedBy == null && reason == null && tenantId == null
                    && notifiedAt == null;
            case ACCEPTED -> decided && reason == null && tenantId != null;
            case REJECTED -> decided && reason != null && tenantId == null;
        };
        if (!consistent) {
            throw new IllegalArgumentException("Inconsistent academy request in state " + status);
        }
    }

    public static AcademyRequest submit(AcademyRequestId id, Requester requester, AcademyName name, Instant now) {
        return new AcademyRequest(id, AcademyRequestStatus.PENDING, requester, name, now, null, null, null, null,
                null);
    }

    public boolean isPending() {
        return status == AcademyRequestStatus.PENDING;
    }

    /** The academy {@code tenant} was created for this request by {@code decidedBy} (the super admin's subject). */
    public AcademyRequest accept(TenantId tenant, String decidedBy, Instant now) {
        requirePending();
        return new AcademyRequest(id, AcademyRequestStatus.ACCEPTED, requester, academyName, requestedAt,
                Objects.requireNonNull(now, "now"), Objects.requireNonNull(decidedBy, "decidedBy"), null,
                Objects.requireNonNull(tenant, "tenant"), null);
    }

    /** Rejected with a reason written for the requester (1..500 characters, line breaks allowed). */
    public AcademyRequest reject(String reason, String decidedBy, Instant now) {
        requirePending();
        return new AcademyRequest(id, AcademyRequestStatus.REJECTED, requester, academyName, requestedAt,
                Objects.requireNonNull(now, "now"), Objects.requireNonNull(decidedBy, "decidedBy"),
                Require.text(reason, "reason", MAX_REASON), null, null);
    }

    /** The decision e-mail was handed to the mail server at {@code now}. */
    public AcademyRequest notified(Instant now) {
        if (isPending()) {
            throw new IllegalStateException("A pending request has no decision to notify");
        }
        return new AcademyRequest(id, status, requester, academyName, requestedAt, decidedAt, decidedBy, reason,
                tenantId, now);
    }

    private void requirePending() {
        if (!isPending()) {
            throw new ConflictException("The request has already been " + status.name().toLowerCase(java.util.Locale.ROOT),
                    "REQUEST_NOT_PENDING");
        }
    }
}
