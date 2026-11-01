package com.hoopsacademy.common.fixturetests;

import com.hoopsacademy.common.tenancy.TenantId;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;

final class SampleFixtures {

    private SampleFixtures() {}

    /** Parent row in the same tenant; the migrator connection already has app.tenant_id = tenant. */
    static UUID insertWidget(Connection migrator, TenantId tenant) throws SQLException {
        try (PreparedStatement ps = migrator.prepareStatement(
                "insert into core.sample_widget (tenant_id, name, size_cm) values (?, 'parent', 1) returning id")) {
            ps.setObject(1, tenant.value());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, UUID.class);
            }
        }
    }
}
