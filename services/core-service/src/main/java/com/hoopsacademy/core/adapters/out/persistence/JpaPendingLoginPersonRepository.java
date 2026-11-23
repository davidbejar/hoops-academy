package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.application.port.PendingLoginPersons;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.PersonId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.function.Function;

/**
 * Per-academy statements of the temporary password sweep (ADR-0028), in a transaction with NO tenant bound, as
 * core_app. First the login's membership index rows are read through the {@code own_memberships} subject policy
 * ({@link MembershipRepository#ofSubject}: nil tenant + {@code app.subject}); then, for each academy,
 * {@code app.tenant_id} is set to that academy (transaction-local) so its RLS policies decide what the {@code exists}
 * probe sees and where the audit row may go ({@link AuditLog#recordFor}). Only native SQL runs (ADR-0026); both
 * settings are put back afterwards, also on failure.
 */
@ApplicationScoped
class JpaPendingLoginPersonRepository implements PendingLoginPersons {

    private final EntityManager em;
    private final BoundTenant boundTenant;
    private final MembershipRepository memberships;
    private final AuditLog audit;

    JpaPendingLoginPersonRepository(EntityManager em, BoundTenant boundTenant, MembershipRepository memberships,
            AuditLog audit) {
        this.em = em;
        this.boundTenant = boundTenant;
        this.memberships = memberships;
        this.audit = audit;
    }

    @Override
    public int recordForEach(String subject, UserId login, Function<PersonId, AuditEvent> event) {
        if (boundTenant.isBound()) {
            throw new IllegalStateException("recordForEach must not run inside a tenant-bound transaction");
        }
        String previousTenant = SessionSettings.current(em, SessionSettings.TENANT);
        String previousSubject = SessionSettings.current(em, SessionSettings.SUBJECT);
        try {
            int written = 0;
            for (IndexedMembership membership : memberships.ofSubject(subject)) {
                SessionSettings.set(em, SessionSettings.TENANT, membership.tenant().toString());
                if (pending(membership.person(), login)) {
                    audit.recordFor(membership.tenant(), event.apply(membership.person()));
                    written++;
                }
            }
            return written;
        } finally {
            SessionSettings.set(em, SessionSettings.TENANT, previousTenant);
            SessionSettings.set(em, SessionSettings.SUBJECT, previousSubject);
        }
    }

    private boolean pending(PersonId person, UserId login) {
        return (Boolean) em.createNativeQuery("""
                select exists (select 1 from core.person
                                where id = :person and user_id = :login and active
                                  and invitation_status = 'PENDING')""")
                .setParameter("person", person.value())
                .setParameter("login", login.value())
                .getSingleResult();
    }
}
