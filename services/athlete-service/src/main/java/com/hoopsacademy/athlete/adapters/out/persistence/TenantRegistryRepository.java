package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import javax.sql.DataSource;

/**
 * JDBC access to the global {@code athlete.tenant_registry} table. Plain JDBC on purpose: the table has no tenant
 * column, so it must work without a bound tenant (the nightly job lists tenants before entering any of them).
 */
@ApplicationScoped
class TenantRegistryRepository implements TenantRegistry {

    private final DataSource dataSource;

    TenantRegistryRepository(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void register(TenantId tenant, ZoneId zone) {
        execute("insert into athlete.tenant_registry (id, timezone) values (?::uuid, ?) "
                + "on conflict (id) do update set timezone = excluded.timezone, updated_at = now()", tenant, zone);
    }

    @Override
    public void registerIfAbsent(TenantId tenant, ZoneId zone) {
        execute("insert into athlete.tenant_registry (id, timezone) values (?::uuid, ?) on conflict (id) do nothing",
                tenant, zone);
    }

    @Override
    public Optional<ZoneId> zoneOf(TenantId tenant) {
        try (Connection c = dataSource.getConnection();
                PreparedStatement ps = c.prepareStatement("select timezone from athlete.tenant_registry where id = ?::uuid")) {
            ps.setString(1, tenant.toString());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(ZoneId.of(rs.getString(1))) : Optional.empty();
            }
        } catch (SQLException e) {
            throw new IllegalStateException("tenant_registry lookup failed", e);
        }
    }

    @Override
    public List<TenantId> tenants() {
        try (Connection c = dataSource.getConnection();
                PreparedStatement ps = c.prepareStatement("select id from athlete.tenant_registry order by id");
                ResultSet rs = ps.executeQuery()) {
            List<TenantId> tenants = new ArrayList<>();
            while (rs.next()) {
                tenants.add(new TenantId(rs.getObject(1, UUID.class)));
            }
            return tenants;
        } catch (SQLException e) {
            throw new IllegalStateException("tenant_registry listing failed", e);
        }
    }

    private void execute(String sql, TenantId tenant, ZoneId zone) {
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, tenant.toString());
            ps.setString(2, zone.getId());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new IllegalStateException("tenant_registry update failed", e);
        }
    }
}
