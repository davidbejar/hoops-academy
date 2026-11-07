package com.hoopsacademy.core.application.events;

import com.hoopsacademy.common.tenancy.TenantId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * The pure rules of {@link BackfillRosterEvents} (WP81; kept apart for PIT in WP88): the order of the topics, which
 * live aggregates still lack an event, the id each event is keyed by, and the chunks one transaction appends.
 */
final class BackfillPlan {

    /** Tenant first (consumers read its time zone and status), then the members, then what refers to them. */
    static final List<EventTopic> ORDER = List.of(EventTopic.TENANT, EventTopic.PERSON, EventTopic.PLAYER,
            EventTopic.TEAM, EventTopic.TEAM_PLAYER, EventTopic.TEAM_STAFF, EventTopic.GUARDIAN_LINK);

    private BackfillPlan() {
    }

    /** The {@code live} aggregates whose id is not among the {@code published} ones, in their order. */
    static List<RosterChange> missing(TenantId tenant, List<RosterChange> live, Collection<String> published) {
        List<RosterChange> missing = new ArrayList<>();
        for (RosterChange change : live) {
            if (!published.contains(aggregateId(tenant, change).toString())) {
                missing.add(change);
            }
        }
        return missing;
    }

    /** The aggregate id each change's event carries (the appender's rule). */
    static UUID aggregateId(TenantId tenant, RosterChange change) {
        return switch (change) {
            case RosterChange.Person person -> person.id().value();
            case RosterChange.Player player -> player.id().value();
            case RosterChange.Team team -> team.id().value();
            case RosterChange.TeamPlayer assignment -> assignment.id().value();
            case RosterChange.TeamStaff entry -> EventTopic.teamStaffId(entry.team().value(), entry.person().value());
            case RosterChange.GuardianLink link -> link.id().value();
            case RosterChange.Tenant ignored -> tenant.value();
            case RosterChange.Season season -> throw new IllegalArgumentException("A season has no event: " + season);
        };
    }

    /** {@code items} in consecutive chunks of {@code size} (the last one may be shorter). */
    static <T> List<List<T>> chunks(List<T> items, int size) {
        List<List<T>> chunks = new ArrayList<>();
        for (int from = 0; from < items.size(); from += size) {
            chunks.add(items.subList(from, Math.min(from + size, items.size())));
        }
        return chunks;
    }
}
