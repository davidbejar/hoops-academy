package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.replica.ParkedEvent;
import com.hoopsacademy.athlete.application.replica.ParkedEvents;
import jakarta.enterprise.context.ApplicationScoped;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import javax.sql.DataSource;

/**
 * The global {@code athlete.parked_event} table. Plain JDBC like {@link TenantRegistryRepository}: a refused record has
 * no trustworthy tenant, so no tenant is bound. The app role may only insert (no conflict target: inferring one would
 * need SELECT); parking a record again (a replay) keeps the first row.
 */
@ApplicationScoped
class ParkedEventRepository implements ParkedEvents {

    private final DataSource dataSource;

    ParkedEventRepository(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void park(ParkedEvent event) {
        try (Connection c = dataSource.getConnection(); PreparedStatement ps = c.prepareStatement("""
                insert into athlete.parked_event (topic, partition, kafka_offset, record_key, event_id, reason)
                values (?, ?, ?, ?, ?, ?)
                on conflict do nothing""")) {
            ps.setString(1, event.topic());
            ps.setInt(2, event.partition());
            ps.setLong(3, event.offset());
            ps.setString(4, event.key().orElse(null));
            if (event.eventId().isPresent()) {
                ps.setObject(5, event.eventId().get());
            } else {
                ps.setNull(5, Types.OTHER);
            }
            ps.setString(6, event.reason());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new IllegalStateException("parked_event insert failed", e);
        }
    }
}
