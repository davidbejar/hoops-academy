package com.hoopsacademy.common.sample;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import java.util.UUID;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class HibernateTenantResolverTest {

    @Inject
    TenantScope tenantScope;

    @Inject
    EntityManager entityManager;

    @Test
    void hibernateFillsTheTenantColumnFromTheContext() {
        TenantId tenant = TenantId.random();

        SampleWidget saved = tenantScope.runAs(tenant, () -> persist(new SampleWidget("hoop", 45)));

        assertThat(saved.tenantId()).isEqualTo(tenant.toString());
    }

    @Test
    void entitiesOfOtherTenantsAreInvisible() {
        TenantId tenantA = TenantId.random();
        TenantId tenantB = TenantId.random();
        UUID id = tenantScope.runAs(tenantA, () -> persist(new SampleWidget("ball", 24))).id();

        assertThat(tenantScope.runAs(tenantA, () -> entityManager.find(SampleWidget.class, id))).isNotNull();
        assertThat(tenantScope.runAs(tenantB, () -> countById(id))).isZero();
    }

    private SampleWidget persist(SampleWidget widget) {
        entityManager.persist(widget);
        entityManager.flush();
        return widget;
    }

    private long countById(UUID id) {
        return entityManager.createQuery("select count(w) from SampleWidget w where w.id = :id", Long.class)
                .setParameter("id", id)
                .getSingleResult();
    }
}
