package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.application.port.SharedLoginPersons;
import com.hoopsacademy.core.domain.identity.UserId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.UUID;
import java.util.function.Supplier;

/**
 * Person rows of another tenant, written inside the bound tenant's transaction (ADR-0026). The bound tenant's pending
 * entity writes are flushed first (they must reach Postgres under their own binding; explicit, so it does not depend
 * on the flush mode auto-flushing before native queries), then {@code app.tenant_id} is
 * set to the other tenant for this adapter's native statements only — still as core_app, so that tenant's RLS
 * policies decide what is visible and writable — and set back to the bound tenant afterwards. Hibernate's
 * {@code @TenantId} filter stays on the bound tenant, which is why only native SQL runs while the other tenant is
 * bound.
 */
@ApplicationScoped
class JpaSharedLoginPersonRepository implements SharedLoginPersons {

    private final EntityManager em;
    private final BoundTenant boundTenant;
    private final AuditLog audit;

    JpaSharedLoginPersonRepository(EntityManager em, BoundTenant boundTenant, AuditLog audit) {
        this.em = em;
        this.boundTenant = boundTenant;
        this.audit = audit;
    }

    @Override
    public boolean emailTaken(IndexedMembership linked, String email) {
        return asTenant(linked.tenant(), () -> (Boolean) em.createNativeQuery("""
                select exists (select 1 from core.person where lower(email) = lower(:email) and id <> :person)""")
                .setParameter("email", email)
                .setParameter("person", linked.person().value())
                .getSingleResult());
    }

    @Override
    public boolean changeEmail(IndexedMembership linked, UserId login, String email, AuditEvent event) {
        return asTenant(linked.tenant(), () -> {
            int changed = em.createNativeQuery("""
                    update core.person set email = :email where id = :person and user_id = :login and active""")
                    .setParameter("email", email)
                    .setParameter("person", linked.person().value())
                    .setParameter("login", login.value())
                    .executeUpdate();
            if (changed == 0) {
                return false;
            }
            audit.recordFor(linked.tenant(), event);
            return true;
        });
    }

    private <T> T asTenant(TenantId other, Supplier<T> statements) {
        UUID home = boundTenant.id();
        if (other.value().equals(home)) {
            throw new IllegalArgumentException("Another tenant's person expected, got one of the bound tenant");
        }
        em.flush();
        bindTenant(other.value());
        T result;
        try {
            result = statements.get();
        } catch (RuntimeException failure) {
            restoreAfter(failure, home);
            throw failure;
        }
        bindTenant(home);
        return result;
    }

    /** The transaction rolls back anyway; a restore that fails on the aborted transaction must not hide the cause. */
    private void restoreAfter(RuntimeException failure, UUID home) {
        try {
            bindTenant(home);
        } catch (RuntimeException restore) {
            failure.addSuppressed(restore);
        }
    }

    private void bindTenant(UUID tenant) {
        em.createNativeQuery("select set_config('app.tenant_id', :tenant, true)")
                .setParameter("tenant", tenant.toString())
                .getSingleResult();
    }
}
