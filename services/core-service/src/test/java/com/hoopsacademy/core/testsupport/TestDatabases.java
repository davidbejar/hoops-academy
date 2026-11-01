package com.hoopsacademy.core.testsupport;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import org.eclipse.microprofile.config.ConfigProvider;

/** Connections as the roles {@code RlsTestDatabase} does not cover (the platform role). */
public final class TestDatabases {

    private TestDatabases() {}

    public static Connection openAsPlatform() throws SQLException {
        var config = ConfigProvider.getConfig();
        return DriverManager.getConnection(config.getValue("quarkus.datasource.platform.jdbc.url", String.class),
                "core_platform", "core_platform-test-password");
    }
}
