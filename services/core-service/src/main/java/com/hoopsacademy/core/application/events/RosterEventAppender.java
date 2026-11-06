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
 * (state transfer, ADR-0036), or {@code <aggregate>.removed} with its identity when it is gone by then, whatever deleted
 * it (WP81: every aggregate; the identity is the aggregate id, plus the ends of a staff entry or a guardian link). Derived state is
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
            case RosterChange.Person person -> states.person(person.id()).ifPresentOrElse(state -> {
                changed(tenant, EventTopic.PERSON, person.id().value(), RosterPayloads.person(state));
                state.player().ifPresent(player -> pending.add(new RosterChange.Player(player)));
            }, () -> removed(tenant, EventTopic.PERSON, person.id().value()));
            case RosterChange.Player player -> states.player(player.id()).ifPresentOrElse(
                    state -> changed(tenant, EventTopic.PLAYER, player.id().value(), RosterPayloads.player(state)),
                    () -> removed(tenant, EventTopic.PLAYER, player.id().value()));
            case RosterChange.Team team -> states.team(team.id()).ifPresentOrElse(
                    state -> changed(tenant, EventTopic.TEAM, team.id().value(), RosterPayloads.team(state)),
                    () -> removed(tenant, EventTopic.TEAM, team.id().value()));
            case RosterChange.Season season ->
                    states.teamsOfSeason(season.id()).forEach(team -> pending.add(new RosterChange.Team(team)));
            case RosterChange.TeamPlayer assignment -> states.teamPlayer(assignment.id()).ifPresentOrElse(
                    state -> changed(tenant, EventTopic.TEAM_PLAYER, assignment.id().value(),
                            RosterPayloads.teamPlayer(state)),
                    () -> removed(tenant, EventTopic.TEAM_PLAYER, assignment.id().value()));
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
            case RosterChange.Tenant ignored -> states.tenant().ifPresentOrElse(
                    state -> changed(tenant, EventTopic.TENANT, tenant.value(), RosterPayloads.tenant(state)),
                    () -> outbox.write(TenantEvents.removed(tenant)));
        }
    }

    private void changed(TenantId tenant, EventTopic topic, UUID aggregate, Map<String, Object> payload) {
        outbox.write(new OutboxEvent(tenant, topic.changedType(), topic.aggregate(), aggregate.toString(), payload,
                topic.topic()));
    }

    /** An aggregate whose id is its whole identity: the payload is empty. */
    private void removed(TenantId tenant, EventTopic topic, UUID aggregate) {
        removed(tenant, topic, aggregate, Map.of());
    }

    private void removed(TenantId tenant, EventTopic topic, UUID aggregate, Map<String, Object> identity) {
        outbox.write(new OutboxEvent(tenant, topic.removedType(), topic.aggregate(), aggregate.toString(), identity,
                topic.topic()));
    }

}
