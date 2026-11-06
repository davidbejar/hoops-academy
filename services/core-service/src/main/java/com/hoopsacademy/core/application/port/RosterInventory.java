package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.events.EventTopic;
import com.hoopsacademy.core.application.events.RosterChange;
import java.util.List;
import java.util.Set;

/** The bound tenant's live roster aggregates and the roster events it has of them (the events backfill, WP81). */
public interface RosterInventory {

    /** Every live aggregate of {@code topic} in the bound tenant, as the change that republishes it. */
    List<RosterChange> live(EventTopic topic);

    /** The aggregate ids of {@code topic} with at least one roster event in the outbox after {@code afterSeq}. */
    Set<String> withEvents(EventTopic topic, long afterSeq);

    /** The highest outbox {@code seq} of the bound tenant, 0 when its outbox is empty. */
    long lastSeq();
}
