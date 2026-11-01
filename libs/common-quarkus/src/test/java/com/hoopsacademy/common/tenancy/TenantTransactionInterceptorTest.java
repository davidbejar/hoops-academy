package com.hoopsacademy.common.tenancy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.agroal.api.AgroalDataSource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class TenantTransactionInterceptorTest {

    private static final TenantId TENANT_A = TenantId.parse("0a000000-0000-4000-8000-0000000000aa");

    @Inject
    TenantContext tenantContext;

    @Inject
    TransactionalProbes.Outer outer;

    @Inject
    AgroalDataSource dataSource;

    @AfterEach
    void clearContext() {
        tenantContext.clear();
    }

    @Test
    void setsTenantVariableInsideTransaction() {
        tenantContext.bindTenant(TENANT_A);

        assertThat(outer.required().tenantSetting()).isEqualTo(TENANT_A.toString());
    }

    @Test
    void variableIsTransactionLocalAndGoneAfterCommit() throws SQLException {
        tenantContext.bindTenant(TENANT_A);
        SessionProbe inTransaction = outer.required();
        assertThat(inTransaction.tenantSetting()).isEqualTo(TENANT_A.toString());

        assertThat(sessionWithPid(inTransaction.backendPid()).tenantSetting()).isNull();
    }

    @Test
    void requiresNewRunsOnItsOwnConnectionAndGetsItsOwnValue() {
        tenantContext.bindTenant(TENANT_A);

        List<SessionProbe> probes = outer.requiredThenRequiresNew();

        SessionProbe outerBefore = probes.get(0);
        SessionProbe requiresNew = probes.get(1);
        assertThat(requiresNew.backendPid()).isNotEqualTo(outerBefore.backendPid());
        assertThat(requiresNew.tenantSetting()).isEqualTo(TENANT_A.toString());
        assertThat(probes.get(2)).as("MANDATORY joins the outer transaction").isEqualTo(outerBefore);
        assertThat(probes.get(3)).as("outer transaction unaffected").isEqualTo(outerBefore);
    }

    @Test
    void withoutTenantNothingIsSetSoRlsFailsLoudly() {
        SessionProbe probe = outer.required();

        assertThat(probe.tenantSetting()).isNull();
        assertThatThrownBy(() -> {
            try (Connection c = dataSource.getConnection()) {
                c.createStatement().executeQuery("select app.current_tenant()");
            }
        }).isInstanceOf(SQLException.class).hasMessageContaining("app.tenant_id is not set");
    }

    @Test
    void supportsWithoutActiveTransactionDoesNotSetAnything() {
        tenantContext.bindTenant(TENANT_A);

        assertThat(outer.supportsWithoutTransaction().tenantSetting()).isNull();
    }

    /** Checks out pooled connections until it holds the backend that served the transaction. */
    private SessionProbe sessionWithPid(int pid) throws SQLException {
        List<Connection> held = new ArrayList<>();
        try {
            for (int i = 0; i < 20; i++) {
                Connection c = dataSource.getConnection();
                held.add(c);
                SessionProbe probe = SessionProbe.of(c);
                if (probe.backendPid() == pid) {
                    return probe;
                }
            }
            throw new AssertionError("pooled backend " + pid + " not found");
        } finally {
            for (Connection c : held) {
                c.close();
            }
        }
    }
}
