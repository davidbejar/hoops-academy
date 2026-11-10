package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.common.replica.ParkedPosition;
import com.hoopsacademy.common.replica.ReplicaHistory;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
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
 * The replica's bookkeeping (V4, V6): {@code game.applied_event} on the transaction's connection (RLS: the bound
 * tenant's rows only), and the two global tables {@code game.replica_tenant} and {@code game.parked_event} on a
 * connection of their own, without a tenant (game_app reads the parked rows' coordinates only, V6).
 */
@ApplicationScoped
class JdbcReplicaHistoryRepository extends JdbcRepository implements ReplicaHistory {

    private final EntityManager em;
    private final DataSource dataSource;

    JdbcReplicaHistoryRepository(EntityManager em, DataSource dataSource) {
        this.em = em;
        this.dataSource = dataSource;
    }

    @Override
    EntityManager entityManager() {
        return em;
    }

    @Override
    public List<TenantId> tenants() {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement("select id from game.replica_tenant order by id");
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
        return update("""
                delete from game.applied_event where ctid in (
                  select ctid from game.applied_event where applied_at < ? order by applied_at limit ?
                     for update skip locked)""", statement -> {
            statement.setObject(1, OffsetDateTime.ofInstant(before, ZoneOffset.UTC));
            statement.setInt(2, limit);
        });
    }

    @Override
    public List<ParkedPosition> deleteParkedInspectedBefore(Instant inspectedBefore) {
        try (Connection connection = dataSource.getConnection(); PreparedStatement statement = connection.prepareStatement("""
                delete from game.parked_event where inspected_at < ?
                returning topic, kafka_partition, kafka_offset""")) {
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
