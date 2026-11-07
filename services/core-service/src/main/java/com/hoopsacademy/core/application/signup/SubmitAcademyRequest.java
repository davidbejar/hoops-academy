package com.hoopsacademy.core.application.signup;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.application.port.AcademyRequestRepository;
import com.hoopsacademy.core.domain.signup.AcademyName;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import com.hoopsacademy.core.domain.signup.AcademyRequestId;
import com.hoopsacademy.core.domain.signup.Requester;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import org.jboss.logging.Logger;

/**
 * The public invitation request (ADR-0044). The caller learns only whether the academy name is free: a request beyond
 * {@value #MAX_PENDING_PER_EMAIL} pending ones of the same e-mail is dropped silently, so the answer never depends on
 * the e-mail. Nothing is e-mailed here (no mail to a third party on demand).
 */
@ApplicationScoped
public class SubmitAcademyRequest {

    static final int MAX_PENDING_PER_EMAIL = 3;
    private static final Logger LOG = Logger.getLogger(SubmitAcademyRequest.class);

    private final AcademyRequestRepository requests;
    private final Clock clock;

    public SubmitAcademyRequest(AcademyRequestRepository requests, Clock clock) {
        this.requests = requests;
        this.clock = clock;
    }

    @Transactional
    public void handle(Requester requester, AcademyName academyName) {
        if (requests.tenantNamed(academyName) || requests.openRequestNamed(academyName)) {
            throw new ConflictException("An academy with this name exists or has been requested", "ACADEMY_NAME_TAKEN");
        }
        if (requests.pendingFor(requester.email()) >= MAX_PENDING_PER_EMAIL) {
            LOG.info("Academy request dropped: too many pending requests for one e-mail");
            return;
        }
        AcademyRequest request = AcademyRequest.submit(AcademyRequestId.random(), requester,
                academyName, clock.instant());
        requests.insert(request);
        LOG.infof("Academy request %s received", request.id());
    }
}
