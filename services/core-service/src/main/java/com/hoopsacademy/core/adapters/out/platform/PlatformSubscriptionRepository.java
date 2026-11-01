package com.hoopsacademy.core.adapters.out.platform;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.SubscriptionRepository;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;

@ApplicationScoped
class PlatformSubscriptionRepository implements SubscriptionRepository {

    private final EntityManager em;

    PlatformSubscriptionRepository(@PersistenceUnit("platform") EntityManager em) {
        this.em = em;
    }

    @Override
    public void subscribe(TenantId tenant, String planCode) {
        em.createNativeQuery("insert into billing.tenant_subscription (tenant_id, plan_code) values (:tenant, :plan)")
                .setParameter("tenant", tenant.value())
                .setParameter("plan", planCode)
                .executeUpdate();
    }

    @Override
    public void deleteUnprovisioned(TenantId tenant) {
        em.createNativeQuery("delete from billing.tenant_subscription where tenant_id = :tenant")
                .setParameter("tenant", tenant.value())
                .executeUpdate();
    }
}
