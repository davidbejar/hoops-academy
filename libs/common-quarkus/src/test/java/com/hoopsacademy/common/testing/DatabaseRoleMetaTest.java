package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;

import io.agroal.api.AgroalDataSource;
import io.quarkus.arc.Arc;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * The service never connects as a role that row-level security ignores (superuser, BYPASSRLS, table owner). Every
 * service subclasses it ({@code @QuarkusTest @WithTestResource(PostgresRlsResource.class)}); the pre-push hook runs
 * all subclasses ({@code just db-role-check}). It checks both halves: the users the service SHIPS with (production
 * config, which the test resource overrides at test time) and those roles as the real bootstrap SQL creates them.
 */
@Tag("db-role")
public abstract class DatabaseRoleMetaTest {

    @Test
    void shippedConfigurationConnectsAsTheAppRoleAndMigratesAsTheOwner() {
        RlsTestDatabase db = RlsTestDatabase.fromConfig();
        ShippedDatasources shipped = ShippedDatasources.load();

        assertThat(shipped.users()).as("datasource users in application.properties (prod profile)")
                .containsEntry(ShippedDatasources.DEFAULT, db.appRole());
        assertThat(shipped.flywayUser()).as("Flyway user").isEqualTo(db.migratorRole());
        assertThat(shipped.users().values()).as("no datasource connects as the schema owner or the superuser")
                .doesNotContain(db.migratorRole(), "postgres");
    }

    @Test
    void everyShippedDatasourceUserIsBoundByRowLevelSecurity() throws SQLException {
        Map<String, List<String>> violations = new TreeMap<>();
        for (Map.Entry<String, String> datasource : ShippedDatasources.load().users().entrySet()) {
            try (Connection c = RlsTestDatabase.fromConfig().openAs(datasource.getValue())) {
                List<String> found = DatabaseRoleCheck.violations(c);
                if (!found.isEmpty()) {
                    violations.put("datasource " + datasource.getKey() + " (" + datasource.getValue() + ")", found);
                }
            }
        }
        assertThat(violations).as("datasources whose role row-level security does not bind").isEmpty();
    }

    @Test
    void theRunningApplicationPoolIsTheAppRole() throws SQLException {
        try (Connection c = Arc.container().instance(AgroalDataSource.class).get().getConnection()) {
            assertThat(DatabaseRoleCheck.currentUser(c)).isEqualTo(RlsTestDatabase.fromConfig().appRole());
            assertThat(DatabaseRoleCheck.violations(c)).isEmpty();
        }
    }
}
