package com.hoopsacademy.athlete.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.common.replica.CoreEventDecoder;
import com.hoopsacademy.common.replica.DecodedEvent;
import com.hoopsacademy.common.replica.ReplicaOutcome;
import java.util.Arrays;
import java.util.List;

/** Feeds {@link CoreEvents} records straight into the replica (decoder + use case, no broker). */
public final class ReplicaFeed {

    private final CoreEventDecoder<RosterEvent> decoder;
    private final ApplyRosterEvent apply;

    public ReplicaFeed(CoreEventDecoder<RosterEvent> decoder, ApplyRosterEvent apply) {
        this.decoder = decoder;
        this.apply = apply;
    }

    public ReplicaOutcome apply(CoreEvents.Record record) {
        DecodedEvent<RosterEvent> decoded = decoder.decode(record.topic(), record.key(), record.value());
        assertThat(decoded).as("%s must decode", record.value()).isInstanceOf(DecodedEvent.Valid.class);
        return apply.apply(((DecodedEvent.Valid<RosterEvent>) decoded).event());
    }

    public List<ReplicaOutcome> apply(CoreEvents.Record... records) {
        return Arrays.stream(records).map(this::apply).toList();
    }
}
