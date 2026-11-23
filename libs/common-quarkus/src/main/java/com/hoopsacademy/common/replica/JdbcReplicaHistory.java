package com.hoopsacademy.common.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import javax.sql.DataSource;

/**
 * The replica's bookkeeping tables of one service schema (ADR-0037 amendment WP82): {@code applied_event} on the
 * current transaction's connection (inside a JTA transaction Agroal hands out the connection enlisted in it, which
 * carries the bound tenant: RLS shows that tenant's rows only), and the global {@code replica_tenant} and
 * {@code parked_event} without a tenant (the app role reads the parked rows' coordinates only).
 */
public final class JdbcReplicaHistory implements ReplicaHistory {

    private final DataSource dataSource;
    private final String listTenants;
    private final String deleteApplied;
    private final String deleteParked;

    public JdbcReplicaHistory(DataSource dataSource, ReplicaSchema schema) {
        this.dataSource = dataSource;
        String applied = schema.table("applied_event");
        this.listTenants = "select id from " + schema.table("replica_tenant") + " order by id";
        this.deleteApplied = "delete from " + applied + " where ctid in (select ctid from " + applied
                + " where applied_at < ? order by applied_at limit ? for update skip locked)";
        this.deleteParked = "delete from " + schema.table("parked_event")
                + " where inspected_at < ? returning topic, partition, kafka_offset";
    }

    @Override
    public List<TenantId> tenants() {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(listTenants);
                ResultSet rows = statement.executeQuery()) {
            List<TenantId> tenants = new ArrayList<>();
            while (rows.next()) {
                tenants.add(new TenantId(rows.getObject(1, UUID.class)));
            }
            return tenants;
        } catch (SQLException e) {
            throw new IllegalStateException("listing the replica's tenants failed", e);
        }
    }

    @Override
    public int deleteAppliedBefore(Instant before, int limit) {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(deleteApplied)) {
            statement.setObject(1, OffsetDateTime.ofInstant(before, ZoneOffset.UTC));
            statement.setInt(2, limit);
            return statement.executeUpdate();
        } catch (SQLException e) {
            throw new IllegalStateException("pruning the applied events failed", e);
        }
    }

    @Override
    public List<ParkedPosition> deleteParkedInspectedBefore(Instant inspectedBefore) {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(deleteParked)) {
            statement.setObject(1, OffsetDateTime.ofInstant(inspectedBefore, ZoneOffset.UTC));
            List<ParkedPosition> deleted = new ArrayList<>();
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    deleted.add(new ParkedPosition(rows.getString(1), rows.getInt(2), rows.getLong(3)));
                }
            }
            return deleted;
        } catch (SQLException e) {
            throw new IllegalStateException("pruning the parked records failed", e);
        }
    }
}
