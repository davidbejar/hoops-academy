package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.signup.AcademyName;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import com.hoopsacademy.core.domain.signup.AcademyRequestId;
import com.hoopsacademy.core.domain.signup.AcademyRequestStatus;
import java.util.Optional;

/**
 * Requests for a new academy (platform datasource, {@code core.academy_request}, ADR-0044). Academy names are compared
 * by the database ({@code core.academy_name_key}), the same way for requests and for the tenant registry.
 */
public interface AcademyRequestRepository {

    /** @throws com.hoopsacademy.common.problem.ConflictException {@code ACADEMY_NAME_TAKEN} on a concurrent duplicate */
    void insert(AcademyRequest request);

    /** Whether an academy of the registry has this name. */
    boolean tenantNamed(AcademyName name);

    /** Whether a pending or accepted request has this name. */
    boolean openRequestNamed(AcademyName name);

    long pendingFor(String email);

    Optional<AcademyRequest> find(AcademyRequestId id);

    /** Newest first. */
    PageResult<AcademyRequest> list(Optional<AcademyRequestStatus> status, PageRequest page);

    /**
     * Stores the decision of a request that is still PENDING in the database.
     *
     * @return false when another decision came first (nothing written)
     */
    boolean decide(AcademyRequest decided);

    /** Compensation of a failed onboarding: the acceptance that claimed {@code tenant} goes back to PENDING. */
    void reopen(AcademyRequestId id, TenantId tenant);

    void markNotified(AcademyRequest notified);
}
