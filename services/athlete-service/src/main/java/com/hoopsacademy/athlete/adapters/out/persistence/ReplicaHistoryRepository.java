package com.hoopsacademy.athlete.adapters.out.persistence;

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
 * The replica's bookkeeping (V6, V9): {@code athlete.applied_event} in the caller's transaction (RLS: the bound
 * tenant's rows only), and the global {@code athlete.replica_tenant} and {@code athlete.parked_event} with plain JDBC
 * like {@link TenantRegistryRepository}, without a tenant (athlete_app reads the parked rows' coordinates only, V9).
 */
@ApplicationScoped
class ReplicaHistoryRepository implements ReplicaHistory {

    private final EntityManager em;
    private final DataSource dataSource;

    ReplicaHistoryRepository(EntityManager em, DataSource dataSource) {
        this.em = em;
        this.dataSource = dataSource;
    }

    @Override
    public List<TenantId> tenants() {
        try (Connection c = dataSource.getConnection();
                PreparedStatement ps = c.prepareStatement("select id from athlete.replica_tenant order by id");
                ResultSet rs = ps.executeQuery()) {
            List<TenantId> tenants = new ArrayList<>();
            while (rs.next()) {
                tenants.add(new TenantId(rs.getObject(1, UUID.class)));
            }
            return tenants;
        } catch (SQLException e) {
            throw new IllegalStateException("replica_tenant listing failed", e);
        }
    }

    @Override
    public int deleteAppliedBefore(Instant before, int limit) {
        return em.createNativeQuery("""
                        delete from athlete.applied_event where ctid in (
                          select ctid from athlete.applied_event where applied_at < :before order by applied_at
                           limit :limit for update skip locked)""")
                .setParameter("before", OffsetDateTime.ofInstant(before, ZoneOffset.UTC))
                .setParameter("limit", limit)
                .executeUpdate();
    }

    @Override
    public List<ParkedPosition> deleteParkedInspectedBefore(Instant inspectedBefore) {
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement("""
                delete from athlete.parked_event where inspected_at < ?
                returning topic, partition, kafka_offset""")) {
            ps.setObject(1, OffsetDateTime.ofInstant(inspectedBefore, ZoneOffset.UTC));
            List<ParkedPosition> deleted = new ArrayList<>();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    deleted.add(new ParkedPosition(rs.getString(1), rs.getInt(2), rs.getLong(3)));
                }
            }
            return deleted;
        } catch (SQLException e) {
            throw new IllegalStateException("parked_event pruning failed", e);
        }
    }
}
