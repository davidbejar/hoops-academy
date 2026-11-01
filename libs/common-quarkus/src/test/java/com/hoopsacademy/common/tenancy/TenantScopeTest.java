package com.hoopsacademy.common.tenancy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.agroal.api.AgroalDataSource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class TenantScopeTest {

    @Inject
    TenantScope tenantScope;

    @Inject
    TenantContext tenantContext;

    @Inject
    AgroalDataSource dataSource;

    @AfterEach
    void clearContext() {
        tenantContext.clear();
    }

    @Test
    void runsWorkInOwnTransactionWithTenantVariableSet() {
        TenantId tenant = TenantId.random();

        SessionProbe probe = tenantScope.runAs(tenant, () -> SessionProbe.of(dataSource));

        assertThat(probe.tenantSetting()).isEqualTo(tenant.toString());
    }

    @Test
    void clearsTheContextAfterwards() {
        tenantScope.runAs(TenantId.random(), () -> tenantContext.requireTenantId());

        assertThat(tenantContext.tenantId()).isEmpty();
    }

    @Test
    void restoresAnOuterTenantAndClearsEvenWhenTheWorkFails() {
        TenantId outer = TenantId.random();
        tenantContext.bindTenant(outer);

        assertThatThrownBy(() -> tenantScope.runAs(TenantId.random(), (Runnable) () -> {
            throw new IllegalStateException("job failed");
        })).hasMessage("job failed");

        assertThat(tenantContext.tenantId()).contains(outer);
    }

    @Test
    void worksWithoutAnActiveRequestContextLikeAScheduledJob() {
        TenantId tenant = TenantId.random();
        AtomicReference<String> seen = new AtomicReference<>();

        CompletableFuture.runAsync(() -> tenantScope.runAs(tenant, () -> seen.set(SessionProbe.of(dataSource).tenantSetting())))
                .join();

        assertThat(seen.get()).isEqualTo(tenant.toString());
    }

    @Test
    void isolatesRowsBetweenTenantsThroughRls() {
        TenantId tenantA = TenantId.random();
        TenantId tenantB = TenantId.random();
        UUID widget = tenantScope.runAs(tenantA, () -> insertWidget(tenantA));

        assertThat(tenantScope.runAs(tenantA, () -> countWidget(widget))).isEqualTo(1);
        assertThat(tenantScope.runAs(tenantB, () -> countWidget(widget))).isZero();
    }

    @Test
    void rollsBackTheJobTransactionOnFailure() {
        TenantId tenant = TenantId.random();
        AtomicReference<UUID> widget = new AtomicReference<>();

        assertThatThrownBy(() -> tenantScope.runAs(tenant, (Runnable) () -> {
            widget.set(insertWidget(tenant));
            throw new IllegalStateException("abort");
        }));

        assertThat(tenantScope.runAs(tenant, () -> countWidget(widget.get()))).isZero();
    }

    private UUID insertWidget(TenantId tenant) {
        try (Connection c = dataSource.getConnection();
                PreparedStatement ps = c.prepareStatement(
                        "insert into core.sample_widget (tenant_id, name, size_cm) values (?, 'w', 1) returning id")) {
            ps.setObject(1, tenant.value());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, UUID.class);
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private int countWidget(UUID id) {
        try (Connection c = dataSource.getConnection();
                PreparedStatement ps = c.prepareStatement("select count(*) from core.sample_widget where id = ?")) {
            ps.setObject(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }
}
