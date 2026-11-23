-- game-service WP126 (X-01): a record's position in its topic is unique in the parking table, as in athlete (V6), so a
-- replay (reset offsets, events-backfill) parks a record once: the insert is "on conflict do nothing". Rows parked
-- twice before this migration are merged first: the oldest stays, inspected when any copy was. Runs as game_migrator.
update game.parked_event kept
   set inspected_at = copies.inspected_at
  from (select min(id) as id, max(inspected_at) as inspected_at
          from game.parked_event
         group by topic, kafka_partition, kafka_offset
        having count(*) > 1) copies
 where kept.id = copies.id and kept.inspected_at is null and copies.inspected_at is not null;

delete from game.parked_event later
 using game.parked_event earlier
 where later.topic = earlier.topic and later.kafka_partition = earlier.kafka_partition
   and later.kafka_offset = earlier.kafka_offset and later.id > earlier.id;

alter table game.parked_event
  add constraint parked_event_position_key unique (topic, kafka_partition, kafka_offset);
