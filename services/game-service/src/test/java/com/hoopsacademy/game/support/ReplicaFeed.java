package com.hoopsacademy.game.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.replica.CoreEventDecoder;
import com.hoopsacademy.common.replica.DecodedEvent;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.application.replica.RosterEvent;
import com.hoopsacademy.game.support.CoreEvents.Record;

/** Applies fixture records to the replica in process (no broker), as the consumer does (tombstones skipped). */
public final class ReplicaFeed {

    private ReplicaFeed() {}

    public static void apply(CoreEventDecoder<RosterEvent> decoder, ReplicateRoster replicate, Record... records) {
        for (Record record : records) {
            if (record.value() == null) {
                continue;
            }
            DecodedEvent<RosterEvent> decoded = decoder.decode(record.topic(), record.key(), record.value());
            assertThat(decoded).as("fixture records follow the contracts").isInstanceOf(DecodedEvent.Valid.class);
            replicate.apply(((DecodedEvent.Valid<RosterEvent>) decoded).event());
        }
    }
}
