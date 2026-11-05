package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.PersonId;
import java.util.function.Function;

/**
 * The persons a login links whose invitation is still PENDING, in every academy (ADR-0028). Used by the temporary
 * password sweep, which runs with no tenant bound and has to leave a trace in each academy's own audit trail.
 */
public interface PendingLoginPersons {

    /**
     * Appends {@code event.apply(person)} to the audit trail of every academy in which {@code login} (subject
     * {@code subject}) links an active person whose invitation is PENDING, inside the caller's transaction, which must
     * have no tenant bound. Each academy's rows are read and written under that academy's own RLS policies.
     *
     * @return the number of academies written to
     */
    int recordForEach(String subject, UserId login, Function<PersonId, AuditEvent> event);
}
