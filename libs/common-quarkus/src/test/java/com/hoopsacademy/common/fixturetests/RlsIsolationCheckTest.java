package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsIsolationCheck;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Proves the generic isolation check fails for leaky tables and explains missing fixtures. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class RlsIsolationCheckTest {

    private final RlsTestDatabase db = RlsTestDatabase.fromConfig();

    @Test
    void passesForAProperlyIsolatedTable() {
        assertThatCode(() -> RlsIsolationCheck.verify(db, "core.sample_widget", Map.of())).doesNotThrowAnyException();
    }

    @Test
    void failsForAPolicyThatLetsEveryTenantRead() throws SQLException {
        withTable("""
                create table core.sample_leaky (id uuid primary key, tenant_id uuid not null, note text not null);
                alter table core.sample_leaky enable row level security;
                alter table core.sample_leaky force row level security;
                create policy leaky_read on core.sample_leaky for select using (true);
                create policy tenant_write on core.sample_leaky for insert with check (tenant_id = app.current_tenant());
                """, () -> assertThatThrownBy(() -> RlsIsolationCheck.verify(db, "core.sample_leaky", Map.of()))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining("core.sample_leaky"));
    }

    @Test
    void failsForAPolicyThatAllowsCrossTenantInserts() throws SQLException {
        withTable("""
                create table core.sample_lax (id uuid primary key, tenant_id uuid not null);
                alter table core.sample_lax enable row level security;
                alter table core.sample_lax force row level security;
                create policy lax on core.sample_lax using (tenant_id = app.current_tenant()) with check (true);
                """, () -> assertThatThrownBy(() -> RlsIsolationCheck.verify(db, "core.sample_lax", Map.of()))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining("42501"));
    }

    @Test
    void explainsWhenAForeignKeyColumnNeedsAFixtureOverride() {
        assertThatThrownBy(() -> RlsIsolationCheck.verify(db, "core.sample_widget_part", Map.of()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("fixtureOverrides()")
                .hasMessageContaining("core.sample_widget_part");
    }

    private void withTable(String ddl, Runnable check) throws SQLException {
        String table = ddl.substring(ddl.indexOf("core."), ddl.indexOf(" (")).strip();
        try (Connection migrator = db.openAsMigrator()) {
            migrator.createStatement().execute(ddl);
            try {
                check.run();
            } finally {
                migrator.createStatement().execute("drop table " + table);
            }
        }
    }
}
