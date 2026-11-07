package com.hoopsacademy.core.application.signup;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.platform.CreateTenant;
import com.hoopsacademy.core.application.platform.CreateTenantCommand;
import com.hoopsacademy.core.application.port.AcademyRequestNotifier;
import com.hoopsacademy.core.application.port.AcademyRequestRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import com.hoopsacademy.core.domain.signup.AcademyRequestId;
import com.hoopsacademy.core.domain.signup.AcademyRequestStatus;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.ZoneId;
import java.util.Objects;
import java.util.Optional;
import org.jboss.logging.Logger;

/**
 * The super admin's workbench (ADR-0044). Accepting claims the request, then onboards the academy exactly as
 * {@code createTenant} does (saga, ADR-0013) with the requester as its first ADMIN; a failed onboarding puts the request
 * back to PENDING. Rejecting stores the reason. Either way the requester is e-mailed afterwards; a failed e-mail
 * leaves {@code notifiedAt} empty and the decision standing.
 */
@ApplicationScoped
public class DecideAcademyRequest {

    private static final Logger LOG = Logger.getLogger(DecideAcademyRequest.class);

    private final AcademyRequestRepository requests;
    private final AcademyRequestSteps steps;
    private final CreateTenant createTenant;
    private final AcademyRequestNotifier notifier;

    public DecideAcademyRequest(AcademyRequestRepository requests, AcademyRequestSteps steps,
            CreateTenant createTenant, AcademyRequestNotifier notifier) {
        this.requests = requests;
        this.steps = steps;
        this.createTenant = createTenant;
        this.notifier = notifier;
    }

    /** What the request does not carry: the academy's handle, zone and language, the administrator's names. */
    public record Acceptance(TenantSlug slug, ZoneId timezone, AppLocale defaultLocale, String givenName,
            String familyName, AppLocale adminLocale) {}

    /** The accepted request and the academy created for it. */
    public record AcceptedAcademy(AcademyRequest request, Tenant tenant) {}

    @Transactional
    public PageResult<AcademyRequest> list(Optional<AcademyRequestStatus> status, PageRequest page) {
        return requests.list(status, page);
    }

    public WithTemporaryPassword<AcceptedAcademy> accept(AcademyRequestId id, Acceptance acceptance,
            String decidedBy) {
        TenantId tenantId = TenantId.random();
        AcademyRequest accepted = steps.claim(id, tenantId, decidedBy);
        WithTemporaryPassword<Tenant> created;
        try {
            created = createTenant.handle(tenantId, command(accepted, acceptance));
        } catch (RuntimeException failure) {
            try {
                steps.release(id, tenantId);
            } catch (RuntimeException releaseFailure) {
                failure.addSuppressed(releaseFailure);
            }
            throw failure;
        }
        steps.recordAcceptance(accepted);
        LOG.infof("Academy request %s accepted: academy %s", id, tenantId);
        boolean newLogin = created.temporaryPassword().isPresent();
        AcademyRequest result = notifyRequester(accepted, notifier.accepted(accepted, newLogin));
        return created.map(tenant -> new AcceptedAcademy(result, tenant));
    }

    public AcademyRequest reject(AcademyRequestId id, String reason, String decidedBy) {
        AcademyRequest rejected = steps.reject(id, reason, decidedBy);
        LOG.infof("Academy request %s rejected", id);
        return notifyRequester(rejected, notifier.rejected(rejected));
    }

    private AcademyRequest notifyRequester(AcademyRequest decided, boolean delivered) {
        if (!delivered) {
            LOG.warnf("Academy request %s: the decision e-mail could not be sent", decided.id());
            return decided;
        }
        return steps.notified(decided);
    }

    private static CreateTenantCommand command(AcademyRequest request, Acceptance acceptance) {
        AppLocale adminLocale = Objects.requireNonNullElse(acceptance.adminLocale(), request.requester().locale());
        return new CreateTenantCommand(acceptance.slug(), request.academyName().value(), acceptance.timezone(),
                acceptance.defaultLocale(), new CreateTenantCommand.FirstAdmin(request.requester().email(),
                        acceptance.givenName(), acceptance.familyName(), adminLocale));
    }
}
