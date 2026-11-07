package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.signup.AcademyRequest;

/**
 * E-mails the requester the super admin's decision in the request's language (ADR-0044). Never the temporary password.
 * Implementations do not throw: a mail that could not be handed to the mail server answers false.
 */
public interface AcademyRequestNotifier {

    /** @param newLogin whether the acceptance created the requester's login (else they sign in with their own) */
    boolean accepted(AcademyRequest request, boolean newLogin);

    boolean rejected(AcademyRequest request);
}
