package com.hoopsacademy.core.application.events;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import com.hoopsacademy.core.application.port.RosterStates;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.ArrayDeque;
import java.util.Collection;
import java.util.Deque;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Turns the aggregates one transaction changed into outbox rows, at the end of that transaction (see
 * {@link RosterChanges}): one {@code <aggregate>.changed} event with the aggregate's whole current state per aggregate
 * (state transfer, ADR-0036), or {@code <aggregate>.removed} with its identity when it is gone. Derived state is
 * followed: a person who is a player changes the player's event too (name, birth date, gender), a season the events
 * of its teams (season dates).
 */
@ApplicationScoped
public class RosterEventAppender {

    private final RosterStates states;
    private final OutboxWriter outbox;

    public RosterEventAppender(RosterStates states, OutboxWriter outbox) {
        this.states = states;
        this.outbox = outbox;
    }

    /** Runs in the tenant's transaction, after its changes are flushed. */
    public void append(TenantId tenant, Collection<RosterChange> changes) {
        Deque<RosterChange> pending = new ArrayDeque<>(changes);
        Set<RosterChange> done = new HashSet<>();
        while (!pending.isEmpty()) {
            RosterChange change = pending.poll();
            if (done.add(change)) {
                append(tenant, change, pending);
            }
        }
    }

    private void append(TenantId tenant, RosterChange change, Deque<RosterChange> pending) {
        switch (change) {
            case RosterChange.Person person -> {
                RosterStates.PersonState state = states.person(person.id()).orElseThrow(() -> missing(change));
                changed(tenant, EventTopic.PERSON, person.id().value(), RosterPayloads.person(state));
                state.player().ifPresent(player -> pending.add(new RosterChange.Player(player)));
            }
            case RosterChange.Player player -> changed(tenant, EventTopic.PLAYER, player.id().value(),
                    RosterPayloads.player(states.player(player.id()).orElseThrow(() -> missing(change))));
            case RosterChange.Team team -> changed(tenant, EventTopic.TEAM, team.id().value(),
                    RosterPayloads.team(states.team(team.id()).orElseThrow(() -> missing(change))));
            case RosterChange.Season season ->
                    states.teamsOfSeason(season.id()).forEach(team -> pending.add(new RosterChange.Team(team)));
            case RosterChange.TeamPlayer assignment -> changed(tenant, EventTopic.TEAM_PLAYER, assignment.id().value(),
                    RosterPayloads.teamPlayer(states.teamPlayer(assignment.id()).orElseThrow(() -> missing(change))));
            case RosterChange.TeamStaff entry -> {
                UUID id = EventTopic.teamStaffId(entry.team().value(), entry.person().value());
                states.teamStaff(entry.team(), entry.person()).ifPresentOrElse(
                        state -> changed(tenant, EventTopic.TEAM_STAFF, id,
                                RosterPayloads.teamStaff(entry.team(), entry.person(), state)),
                        () -> removed(tenant, EventTopic.TEAM_STAFF, id,
                                RosterPayloads.teamStaffIdentity(entry.team(), entry.person())));
            }
            case RosterChange.GuardianLink link -> {
                RosterStates.GuardianLinkState identity = new RosterStates.GuardianLinkState(link.guardian(), link.player());
                states.guardianLink(link.id()).ifPresentOrElse(
                        state -> changed(tenant, EventTopic.GUARDIAN_LINK, link.id().value(), RosterPayloads.guardianLink(state)),
                        () -> removed(tenant, EventTopic.GUARDIAN_LINK, link.id().value(),
                                RosterPayloads.guardianLink(identity)));
            }
            case RosterChange.Tenant ignored -> changed(tenant, EventTopic.TENANT, tenant.value(),
                    RosterPayloads.tenant(states.tenant().orElseThrow(() -> missing(change))));
        }
    }

    private void changed(TenantId tenant, EventTopic topic, UUID aggregate, Map<String, Object> payload) {
        outbox.write(new OutboxEvent(tenant, topic.changedType(), topic.aggregate(), aggregate.toString(), payload,
                topic.topic()));
    }

    private void removed(TenantId tenant, EventTopic topic, UUID aggregate, Map<String, Object> identity) {
        outbox.write(new OutboxEvent(tenant, topic.removedType(), topic.aggregate(), aggregate.toString(), identity,
                topic.topic()));
    }

    private static IllegalStateException missing(RosterChange change) {
        return new IllegalStateException("Changed aggregate not found in the bound tenant: " + change);
    }
}
