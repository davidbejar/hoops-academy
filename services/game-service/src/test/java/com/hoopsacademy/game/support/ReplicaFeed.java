package com.hoopsacademy.game.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder.Decoded;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.support.CoreEvents.Record;

/** Applies fixture records to the replica in process (no broker), as the consumer does (tombstones skipped). */
public final class ReplicaFeed {

    private ReplicaFeed() {}

    public static void apply(RosterEventDecoder decoder, ReplicateRoster replicate, Record... records) {
        for (Record record : records) {
            if (record.value() == null) {
                continue;
            }
            Decoded decoded = decoder.decode(record.topic(), record.key(), record.value());
            assertThat(decoded).as("fixture records follow the contracts").isInstanceOf(Decoded.Valid.class);
            replicate.apply(((Decoded.Valid) decoded).event());
        }
    }
}
