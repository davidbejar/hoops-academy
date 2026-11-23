package com.hoopsacademy.common.replica;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import javax.sql.DataSource;

/**
 * {@code <schema>.parked_event} with plain JDBC and no tenant bound (a refused record has no trustworthy tenant): the
 * app role may only insert there, so the insert has no conflict target (inferring one would need SELECT); a record
 * parked again (a replay) keeps the first row (primary key on its position in the topic).
 */
public final class JdbcParkedEvents implements ParkedEvents {

    private final DataSource dataSource;
    private final String insert;

    public JdbcParkedEvents(DataSource dataSource, ReplicaSchema schema) {
        this.dataSource = dataSource;
        this.insert = "insert into " + schema.table("parked_event")
                + " (topic, partition, kafka_offset, record_key, event_id, reason) values (?, ?, ?, ?, ?, ?)"
                + " on conflict do nothing";
    }

    @Override
    public void park(ParkedEvent event) {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(insert)) {
            statement.setString(1, event.topic());
            statement.setInt(2, event.partition());
            statement.setLong(3, event.offset());
            statement.setString(4, event.key().orElse(null));
            if (event.eventId().isPresent()) {
                statement.setObject(5, event.eventId().get());
            } else {
                statement.setNull(5, Types.OTHER);
            }
            statement.setString(6, event.reason());
            statement.executeUpdate();
        } catch (SQLException e) {
            throw new IllegalStateException("parking a record failed", e);
        }
    }
}
