package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.DatabaseRoleCheck;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.SQLException;
import org.junit.jupiter.api.Test;

/** The role check accepts the non-owner app role and rejects the schema owner. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class DatabaseRoleCheckTest {

    @Test
    void appRoleIsBoundByRowLevelSecurity() throws SQLException {
        try (Connection c = RlsTestDatabase.fromConfig().openAsApp()) {
            assertThat(DatabaseRoleCheck.currentUser(c)).isEqualTo("core_app");
            assertThat(DatabaseRoleCheck.violations(c)).isEmpty();
        }
    }

    @Test
    void schemaOwnerIsReportedForItsTablesAndItsCreatePrivilege() throws SQLException {
        try (Connection c = RlsTestDatabase.fromConfig().openAsMigrator()) {
            assertThat(DatabaseRoleCheck.violations(c))
                    .anySatisfy(v -> assertThat(v).contains("core.sample_widget").contains("owner core_migrator"))
                    .anySatisfy(v -> assertThat(v).contains("CREATE in schema core"));
        }
    }

    @Test
    void openAsConnectsAsTheNamedBootstrapRole() throws SQLException {
        try (Connection c = RlsTestDatabase.fromConfig().openAs("core_platform")) {
            assertThat(DatabaseRoleCheck.currentUser(c)).isEqualTo("core_platform");
        }
    }
}
