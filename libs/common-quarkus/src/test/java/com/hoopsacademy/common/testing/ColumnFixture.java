package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.tenancy.TenantId;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Supplies a column value for a fixture row, e.g. inserts the parent row a foreign key needs. Called with the
 * migrator connection inside its transaction, where {@code app.tenant_id} is already set to {@code tenant}.
 */
@FunctionalInterface
public interface ColumnFixture {

    Object valueFor(Connection migrator, TenantId tenant) throws SQLException;
}
