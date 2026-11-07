package com.hoopsacademy.core.application.signup;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AcademyRequestRepository;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.PlatformAuditLog;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import com.hoopsacademy.core.domain.signup.AcademyRequestId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.Map;
import java.util.function.UnaryOperator;

/** The platform-datasource transactions of a decision (one per step, so the saga in between holds no transaction). */
@ApplicationScoped
class AcademyRequestSteps {

    private final AcademyRequestRepository requests;
    private final PlatformAuditLog audit;
    private final Clock clock;

    AcademyRequestSteps(AcademyRequestRepository requests, PlatformAuditLog audit, Clock clock) {
        this.requests = requests;
        this.audit = audit;
        this.clock = clock;
    }

    /** Claims a pending request for the academy {@code tenant} before anything is created (a second accept gets 409). */
    @Transactional
    AcademyRequest claim(AcademyRequestId id, TenantId tenant, String decidedBy) {
        return decide(id, request -> {
            AcademyRequest accepted = request.accept(tenant, decidedBy, clock.instant());
            if (requests.tenantNamed(request.academyName())) {
                throw new ConflictException("An academy with this name exists already", "ACADEMY_NAME_TAKEN");
            }
            return accepted;
        });
    }

    @Transactional
    void release(AcademyRequestId id, TenantId tenant) {
        requests.reopen(id, tenant);
    }

    @Transactional
    AcademyRequest reject(AcademyRequestId id, String reason, String decidedBy) {
        return decide(id, request -> request.reject(reason, decidedBy, clock.instant()));
    }

    /** The audit row in the new academy's trail (ADR-0029); the actor is the super admin. */
    @Transactional
    void recordAcceptance(AcademyRequest accepted) {
        audit.record(accepted.tenantId(), AuditEvent.of(AuditAction.TENANT_REQUEST_ACCEPTED, accepted.tenantId(),
                Map.of("academyRequestId", accepted.id().toString(),
                        "requesterRole", accepted.requester().role().name())));
    }

    @Transactional
    AcademyRequest notified(AcademyRequest decided) {
        AcademyRequest notified = decided.notified(clock.instant());
        requests.markNotified(notified);
        return notified;
    }

    private AcademyRequest decide(AcademyRequestId id, UnaryOperator<AcademyRequest> decision) {
        AcademyRequest decided = decision.apply(requests.find(id)
                .orElseThrow(() -> new NotFoundException("Academy request not found")));
        if (!requests.decide(decided)) {
            throw new ConflictException("The request has already been decided", "REQUEST_NOT_PENDING");
        }
        return decided;
    }
}
