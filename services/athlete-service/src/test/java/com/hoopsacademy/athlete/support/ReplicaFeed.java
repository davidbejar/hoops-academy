package com.hoopsacademy.athlete.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.adapters.in.messaging.DecodedEvent;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent.Outcome;
import java.util.Arrays;
import java.util.List;

/** Feeds {@link CoreEvents} records straight into the replica (decoder + use case, no broker). */
public final class ReplicaFeed {

    private final CoreEventDecoder decoder;
    private final ApplyRosterEvent apply;

    public ReplicaFeed(CoreEventDecoder decoder, ApplyRosterEvent apply) {
        this.decoder = decoder;
        this.apply = apply;
    }

    public Outcome apply(CoreEvents.Record record) {
        DecodedEvent decoded = decoder.decode(record.topic(), record.key(), record.value());
        assertThat(decoded).as("%s must decode", record.value()).isInstanceOf(DecodedEvent.Valid.class);
        return apply.apply(((DecodedEvent.Valid) decoded).event());
    }

    public List<Outcome> apply(CoreEvents.Record... records) {
        return Arrays.stream(records).map(this::apply).toList();
    }
}
