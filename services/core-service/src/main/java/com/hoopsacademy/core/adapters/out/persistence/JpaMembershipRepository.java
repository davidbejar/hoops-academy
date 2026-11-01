package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.domain.membership.PersonId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.UUID;

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
        return rows.stream().map(Object[].class::cast)
                .map(row -> new IndexedMembership(new TenantId((UUID) row[0]), new PersonId((UUID) row[1])))
                .toList();
    }
}
