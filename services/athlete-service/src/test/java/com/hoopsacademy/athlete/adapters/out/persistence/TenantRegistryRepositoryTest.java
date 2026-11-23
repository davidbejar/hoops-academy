package com.hoopsacademy.athlete.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.ZoneId;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;

/** The global tenant registry: one row per tenant with its zone, rewritten only when the zone changes (ATH-03). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class TenantRegistryRepositoryTest {

    @Inject TenantRegistry registry;
    @Inject DataSource dataSource;

    @Test
    void registeringTheSameZoneAgainWritesNothing() throws SQLException {
        TenantId tenant = TenantId.random();
        registry.register(tenant, ZoneId.of("Europe/Madrid"));
        String firstVersion = rowVersion(tenant);

        registry.register(tenant, ZoneId.of("Europe/Madrid"));

        assertThat(rowVersion(tenant)).isEqualTo(firstVersion);
        assertThat(registry.zoneOf(tenant)).contains(ZoneId.of("Europe/Madrid"));
    }

    @Test
    void aChangedZoneReplacesTheStoredOne() throws SQLException {
        TenantId tenant = TenantId.random();
        registry.register(tenant, ZoneId.of("Europe/Madrid"));
        String firstVersion = rowVersion(tenant);

        registry.register(tenant, ZoneId.of("Asia/Jakarta"));

        assertThat(rowVersion(tenant)).isNotEqualTo(firstVersion);
        assertThat(registry.zoneOf(tenant)).contains(ZoneId.of("Asia/Jakarta"));
        assertThat(registry.tenants()).contains(tenant);
    }

    /** The row's transaction id: a new one after every write, including an update to the same values. */
    private String rowVersion(TenantId tenant) throws SQLException {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(
                        "select xmin::text from athlete.tenant_registry where id = ?::uuid")) {
            statement.setString(1, tenant.toString());
            try (ResultSet row = statement.executeQuery()) {
                assertThat(row.next()).isTrue();
                return row.getString(1);
            }
        }
    }
}
