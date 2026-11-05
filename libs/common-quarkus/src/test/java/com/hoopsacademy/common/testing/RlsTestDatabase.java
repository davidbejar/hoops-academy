package com.hoopsacademy.common.testing;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import org.eclipse.microprofile.config.ConfigProvider;

/** Plain JDBC access to the {@link PostgresRlsResource} database as the service's migrator or app role. */
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
}
