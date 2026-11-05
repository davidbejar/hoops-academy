package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.domain.membership.PersonId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;

/**
 * {@code core.user_membership_index}. Writes use the standard tenant policy. The cross-tenant read binds the nil
 * tenant (the tenant policy then matches nothing instead of raising) plus {@code app.subject}, which the
 * {@code own_memberships} policy compares with each row — so only the caller's own rows are ever visible.
 */
@ApplicationScoped
class JpaMembershipRepository implements MembershipRepository {

    private static final String NIL_TENANT = "00000000-0000-0000-0000-000000000000";

    private final EntityManager em;
    private final BoundTenant boundTenant;

    JpaMembershipRepository(EntityManager em, BoundTenant boundTenant) {
        this.em = em;
        this.boundTenant = boundTenant;
    }

    @Override
    public void register(String subject, PersonId person) {
        em.createNativeQuery("""
                insert into core.user_membership_index (tenant_id, keycloak_sub, person_id)
                values (:tenant, :sub, :person)
                on conflict (tenant_id, keycloak_sub) do update set person_id = excluded.person_id""")
                .setParameter("tenant", boundTenant.id())
                .setParameter("sub", subject)
                .setParameter("person", person.value())
                .executeUpdate();
    }

    @Override
    public void unregister(PersonId person) {
        em.createNativeQuery("delete from core.user_membership_index where person_id = :person")
                .setParameter("person", person.value())
                .executeUpdate();
    }

    /**
     * Inside the bound tenant's transaction: sets {@code app.subject} to {@code subject} for ONE statement, so the
     * {@code own_memberships} policy exposes that login's index rows of other tenants to an {@code exists} probe, then
     * puts the previous value back. Only the boolean leaves this method (ADR-0023).
     */
    @Override
    public boolean linkedInAnotherTenant(String subject) {
        UUID tenant = boundTenant.id();
        return asSubject(subject, () -> (Boolean) em.createNativeQuery("""
                select exists (select 1 from core.user_membership_index
                                where keycloak_sub = :sub and tenant_id <> :tenant)""")
                .setParameter("sub", subject)
                .setParameter("tenant", tenant)
                .getSingleResult());
    }

    /** Like {@link #linkedInAnotherTenant}, for the super admin's login move: which other tenants' persons (ADR-0026). */
    @Override
    public List<IndexedMembership> inOtherTenants(String subject) {
        UUID tenant = boundTenant.id();
        List<?> rows = asSubject(subject, () -> em.createNativeQuery("""
                select tenant_id, person_id from core.user_membership_index
                 where keycloak_sub = :sub and tenant_id <> :tenant order by tenant_id""")
                .setParameter("sub", subject)
                .setParameter("tenant", tenant)
                .getResultList());
        return indexed(rows);
    }

    /** Runs {@code statement} with {@code app.subject} bound to {@code subject}, then puts the previous value back. */
    private <T> T asSubject(String subject, Supplier<T> statement) {
        String previous = (String) em.createNativeQuery("select coalesce(current_setting('app.subject', true), '')")
                .getSingleResult();
        bindSubject(subject);
        try {
            return statement.get();
        } finally {
            bindSubject(previous);
        }
    }

    private static List<IndexedMembership> indexed(List<?> rows) {
        return rows.stream().map(Object[].class::cast)
                .map(row -> new IndexedMembership(new TenantId((UUID) row[0]), new PersonId((UUID) row[1])))
                .toList();
    }

    private void bindSubject(String subject) {
        em.createNativeQuery("select set_config('app.subject', :sub, true)").setParameter("sub", subject)
                .getSingleResult();
    }

    /** Must run in its own transaction with no tenant bound: it rebinds app.tenant_id to the nil tenant. */
    @Override
    public List<IndexedMembership> ofSubject(String subject) {
        if (boundTenant.isBound()) {
            throw new IllegalStateException("ofSubject must not run inside a tenant-bound transaction");
        }
        em.createNativeQuery("select set_config('app.tenant_id', :nil, true), set_config('app.subject', :sub, true)")
                .setParameter("nil", NIL_TENANT)
                .setParameter("sub", subject)
                .getSingleResult();
        List<?> rows = em.createNativeQuery("""
                select tenant_id, person_id from core.user_membership_index
                 where keycloak_sub = :sub order by tenant_id""")
                .setParameter("sub", subject)
                .getResultList();
        return indexed(rows);
    }
}
