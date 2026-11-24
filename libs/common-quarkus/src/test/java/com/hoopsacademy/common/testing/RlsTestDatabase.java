package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.tenancy.TenantId;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import org.eclipse.microprofile.config.ConfigProvider;

/**
 * Plain JDBC access to the {@link PostgresRlsResource} database as the service's migrator or app role, and the one
 * place a test binds a tenant to its transaction (LIB-05: it was written by hand 17 times).
 */
public final class RlsTestDatabase {

    static final String SERVICE_KEY = "hoops.test.db.service";
    static final String JDBC_URL_KEY = "hoops.test.db.jdbc-url";

    private final String jdbcUrl;
    private final String service;

    RlsTestDatabase(String jdbcUrl, String service) {
        this.jdbcUrl = jdbcUrl;
        this.service = service;
    }

    /** Reads the coordinates published by {@link PostgresRlsResource} (call inside a {@code @QuarkusTest}). */
    public static RlsTestDatabase fromConfig() {
        var config = ConfigProvider.getConfig();
        return new RlsTestDatabase(
                config.getValue(JDBC_URL_KEY, String.class), config.getValue(SERVICE_KEY, String.class));
    }

    public String service() {
        return service;
    }

    public String migratorRole() {
        return service + "_migrator";
    }

    public String appRole() {
        return service + "_app";
    }

    /** Owner of the service schema; still subject to RLS because every tenant table is FORCEd. */
    public Connection openAsMigrator() throws SQLException {
        return DriverManager.getConnection(jdbcUrl, migratorRole(), TestRolePasswords.of(migratorRole()));
    }

    /** The runtime role: non-owner, NOBYPASSRLS. */
    public Connection openAsApp() throws SQLException {
        return openAs(appRole());
    }

    /** Any bootstrap role of {@code infra/db/init} (e.g. {@code core_platform}). */
    public Connection openAs(String role) throws SQLException {
        return DriverManager.getConnection(jdbcUrl, role, TestRolePasswords.of(role));
    }

    /**
     * Binds {@code tenant} to the connection's current transaction, as the services' tenancy interceptor does at runtime
     * ({@code app.tenant_id}, transaction-local): call it with auto-commit off, RLS then answers for that tenant.
     */
    public static void bindTenant(Connection connection, TenantId tenant) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
            statement.setString(1, tenant.toString());
            statement.execute();
        }
    }
}
