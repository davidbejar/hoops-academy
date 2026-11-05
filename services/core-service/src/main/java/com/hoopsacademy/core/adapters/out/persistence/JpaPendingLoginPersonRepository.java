package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.PendingLoginPersons;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.PersonId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;

/**
 * Per-academy statements of the temporary password sweep (ADR-0028), in a transaction with NO tenant bound, as
 * core_app. First the login's membership index rows are read through the {@code own_memberships} subject policy (nil
 * tenant + {@code app.subject}, as {@link JpaMembershipRepository#ofSubject}); then, for each academy,
 * {@code app.tenant_id} is set to that academy (transaction-local) so its RLS policies decide what the {@code exists}
 * probe sees and where the audit row may go ({@link AuditLog#recordFor}). Only native SQL runs (ADR-0026); both
 * settings are put back afterwards, also on failure.
 */
@ApplicationScoped
class JpaPendingLoginPersonRepository implements PendingLoginPersons {

    private static final String NIL_TENANT = "00000000-0000-0000-0000-000000000000";

    private final EntityManager em;
    private final BoundTenant boundTenant;
    private final AuditLog audit;

    JpaPendingLoginPersonRepository(EntityManager em, BoundTenant boundTenant, AuditLog audit) {
        this.em = em;
        this.boundTenant = boundTenant;
        this.audit = audit;
    }

    @Override
    public int recordForEach(String subject, UserId login, Function<PersonId, AuditEvent> event) {
        if (boundTenant.isBound()) {
            throw new IllegalStateException("recordForEach must not run inside a tenant-bound transaction");
        }
        String previousTenant = setting("app.tenant_id");
        String previousSubject = setting("app.subject");
        try {
            int written = 0;
            for (Object[] row : indexRows(subject)) {
                TenantId tenant = new TenantId((UUID) row[0]);
                PersonId person = new PersonId((UUID) row[1]);
                set("app.tenant_id", tenant.toString());
                if (pending(person, login)) {
                    audit.recordFor(tenant, event.apply(person));
                    written++;
                }
            }
            return written;
        } finally {
            set("app.tenant_id", previousTenant);
            set("app.subject", previousSubject);
        }
    }

    private List<Object[]> indexRows(String subject) {
        set("app.tenant_id", NIL_TENANT);
        set("app.subject", subject);
        List<?> rows = em.createNativeQuery("""
                select tenant_id, person_id from core.user_membership_index
                 where keycloak_sub = :sub order by tenant_id""")
                .setParameter("sub", subject)
                .getResultList();
        return rows.stream().map(Object[].class::cast).toList();
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

    private String setting(String name) {
        return (String) em.createNativeQuery("select coalesce(current_setting(:name, true), '')")
                .setParameter("name", name)
                .getSingleResult();
    }

    private void set(String name, String value) {
        em.createNativeQuery("select set_config(:name, :value, true)")
                .setParameter("name", name)
                .setParameter("value", value)
                .getSingleResult();
    }
}
