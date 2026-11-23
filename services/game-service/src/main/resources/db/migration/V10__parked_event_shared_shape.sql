-- game-service WP130 (ADR-0062): parked_event gets athlete's shape (athlete V6/V9), so common's JdbcParkedEvents and
-- JdbcReplicaHistory serve both schemas and the runbook has one procedure: the record's position in its topic is the
-- primary key (unique since V8, so no row is lost), the column is named partition, and the surrogate identity id goes
-- (with its sequence and its column grant). game_app keeps insert, delete and select on the coordinates (V6).
-- Runs as game_migrator.
alter table game.parked_event drop constraint parked_event_position_key;
alter table game.parked_event drop column id;
alter table game.parked_event rename column kafka_partition to partition;
alter table game.parked_event add primary key (topic, partition, kafka_offset);
