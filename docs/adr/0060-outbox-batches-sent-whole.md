# ADR-0060: The outbox publisher sends a batch whole, then awaits its acknowledgements

- Status: Accepted
- Date: 2026-11-23
- Related: ADR-0008 (publisher, item 4; amendment of WP81), ADR-0036 (one partition per topic), WP128, audit of
  2026-11-23 (CORE-04)

## Context
The publisher of ADR-0008 locks a batch of up to `hoops.outbox.batch-size` (100) outbox rows of one academy and sends
them while the academy's transaction holds the row locks. `KafkaEventBroker.send` waited for each record's
acknowledgement (`acks=all`) before it handed the next one to the producer, so a batch cost about one broker round trip
per record: a backfill of thousands of events spent tens of seconds waiting serially, with the rows locked all along.
The serial wait bought nothing: the producer is idempotent with Kafka's default of five requests in flight per
connection, which keeps the order per partition through retries, and every core topic has one partition (ADR-0036).

## Decision
1. `EventBroker.sendAll(List<Message>)` hands every record of a batch (each event and, after a removal, its tombstone)
   to the producer in outbox order, then waits for all their acknowledgements within one `hoops.outbox.send-timeout`
   for the whole batch (not one per record). `send(topic, key, value)` stays as a one-record batch.
2. Failure is per batch, as before: any record that is refused or not acknowledged in time fails the call with
   `UnavailableException` naming its topic; the publisher marks nothing published and the next run sends the whole
   batch again with the same `eventId`s (at least once; the consumers ignore a duplicate `eventId`, ADR-0036).
3. The producer reset of the WP81 amendment counts failed **batches** in a row (`hoops.outbox.producer-reset-after`,
   3); before, a failed batch was also one failed send, because the first failure ended it.

## Consequences
- A batch costs about one round trip instead of one per record, and the row locks are held that much shorter.
- A batch that fails part-way may have delivered some of its records before the failure; they are delivered again with
  the next run. This was already possible before (a record whose acknowledgement timed out could still arrive), and the
  consumers' idempotent upserts cover it (a duplicate `eventId` is ignored, an older `occurredAt` never overwrites).
- `send-timeout` now bounds a whole batch: with the defaults, 10 s for up to 100 records (and their tombstones).
