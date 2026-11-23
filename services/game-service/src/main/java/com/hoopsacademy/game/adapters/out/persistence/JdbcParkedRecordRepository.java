package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.game.application.replica.ParkedRecord;
import com.hoopsacademy.game.application.replica.ParkedRecords;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;

/**
 * {@code game.parked_event}: insert only (game_app reads no more than the coordinates, V4/V6). A record parked again
 * (a replay) is a no-op: its position in the topic is unique (V8).
 */
@ApplicationScoped
class JdbcParkedRecordRepository extends JdbcRepository implements ParkedRecords {

    private final EntityManager em;

    JdbcParkedRecordRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    EntityManager entityManager() {
        return em;
    }

    @Override
    public void park(ParkedRecord record) {
        update("""
                insert into game.parked_event (topic, kafka_partition, kafka_offset, record_key, event_id, reason)
                values (?, ?, ?, ?, ?, ?)
                on conflict (topic, kafka_partition, kafka_offset) do nothing""", statement -> {
            statement.setString(1, record.topic());
            statement.setInt(2, record.partition());
            statement.setLong(3, record.offset());
            statement.setString(4, record.key());
            setUuid(statement, 5, record.eventId().orElse(null));
            statement.setString(6, record.reason());
        });
    }
}
