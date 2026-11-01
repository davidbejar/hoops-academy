package com.hoopsacademy.common.tenancy;

import io.agroal.api.AgroalDataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

/** What a database session currently sees: backend pid + transaction-local tenant setting. */
record SessionProbe(int backendPid, String tenantSetting) {

    static SessionProbe of(Connection connection) {
        try (ResultSet rs = connection.createStatement()
                .executeQuery("select pg_backend_pid(), current_setting('app.tenant_id', true)")) {
            rs.next();
            String setting = rs.getString(2);
            return new SessionProbe(rs.getInt(1), setting == null || setting.isEmpty() ? null : setting);
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    static SessionProbe of(AgroalDataSource dataSource) {
        try (Connection connection = dataSource.getConnection()) {
            return of(connection);
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }
}
