package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.PersonChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.PlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamPlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.TenantChanged;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.athlete.application.replica.RosterReplicaStore;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import java.util.function.UnaryOperator;
import java.util.stream.Collectors;

/**
 * Upserts of the athlete.*_ref tables (V6) in the caller's transaction, which {@code ApplyRosterEvent} binds to the
 * event's tenant (RLS). Each upsert writes only when the stored row is not newer ({@code occurred_at <=} the event's):
 * an older event arriving late leaves the row alone and the update count tells the caller. The tenant id is also
 * written explicitly from the event, so a row can never land in another tenant (RLS WITH CHECK would refuse it).
 */
@ApplicationScoped
class RosterReplicaRepository implements RosterReplicaStore {

    /** Appended to every upsert (target aliased {@code r}): write only when the stored state is not newer. */
    private static final String NOT_NEWER = " where r.occurred_at <= excluded.occurred_at";

    private final EntityManager em;

    RosterReplicaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public boolean markApplied(RosterEvent event) {
        return envelope(em.createNativeQuery("""
                insert into athlete.applied_event (tenant_id, event_id, topic, aggregate_id, occurred_at)
                values (:tenant, :event, :topic, :id, :at)
                on conflict (tenant_id, event_id) do nothing"""), event)
                .setParameter("topic", event.topic().topicName())
                .executeUpdate() == 1;
    }

    @Override
    public boolean tenant(RosterEvent event, TenantChanged change) {
        return upsert("""
                insert into athlete.tenant_ref as r (tenant_id, status, timezone, occurred_at, event_id)
                values (:tenant, :status, :zone, :at, :event)
                on conflict (tenant_id) do update set status = excluded.status, timezone = excluded.timezone,
                  occurred_at = excluded.occurred_at, event_id = excluded.event_id, updated_at = now()""", event, q -> q
                .setParameter("status", change.status())
                .setParameter("zone", change.timezone().getId()));
    }

    @Override
    public boolean person(RosterEvent event, PersonChanged change) {
        return upsert("""
                insert into athlete.person_ref as r (tenant_id, id, display_name, subject, roles, active, occurred_at, event_id)
                values (:tenant, :id, :name, cast(:subject as text), cast(:roles as text[]), :active, :at, :event)
                on conflict (tenant_id, id) do update set display_name = excluded.display_name, subject = excluded.subject,
                  roles = excluded.roles, active = excluded.active, occurred_at = excluded.occurred_at,
                  event_id = excluded.event_id, updated_at = now()""", event, q -> q
                .setParameter("name", change.displayName())
                .setParameter("subject", change.subject().orElse(null))
                .setParameter("roles", change.roles().stream().map(Enum::name).sorted()
                        .collect(Collectors.joining(",", "{", "}")))
                .setParameter("active", change.active()));
    }

    @Override
    public boolean player(RosterEvent event, PlayerChanged change) {
        return upsert("""
                insert into athlete.player_ref as r (tenant_id, id, person_id, display_name, status, birth_date, gender,
                  occurred_at, event_id)
                values (:tenant, :id, :person, :name, :status, cast(:birth as date), cast(:gender as text), :at, :event)
                on conflict (tenant_id, id) do update set person_id = excluded.person_id,
                  display_name = excluded.display_name, status = excluded.status, birth_date = excluded.birth_date,
                  gender = excluded.gender, occurred_at = excluded.occurred_at, event_id = excluded.event_id,
                  updated_at = now()""", event, q -> q
                .setParameter("person", change.personId().value())
                .setParameter("name", change.displayName())
                .setParameter("status", change.status())
                .setParameter("birth", date(change.birthDate()))
                .setParameter("gender", change.gender().map(Enum::name).orElse(null)));
    }

    @Override
    public boolean team(RosterEvent event, TeamChanged change) {
        return upsert("""
                insert into athlete.team_ref as r (tenant_id, id, season_id, season_end_date, name, occurred_at, event_id)
                values (:tenant, :id, :season, cast(:seasonEnd as date), :name, :at, :event)
                on conflict (tenant_id, id) do update set season_id = excluded.season_id,
                  season_end_date = excluded.season_end_date, name = excluded.name, occurred_at = excluded.occurred_at,
                  event_id = excluded.event_id, updated_at = now()""", event, q -> q
                .setParameter("season", change.seasonId())
                .setParameter("seasonEnd", change.seasonEndDate().toString())
                .setParameter("name", change.name()));
    }

    @Override
    public boolean teamPlayer(RosterEvent event, TeamPlayerChanged change) {
        return upsert("""
                insert into athlete.team_player_ref as r (tenant_id, id, team_id, player_id, jersey_number, joined_on, left_on,
                  invalid_reason, occurred_at, event_id)
                values (:tenant, :id, :team, :player, cast(:jersey as text), cast(:joined as date), cast(:left as date),
                  cast(:invalid as text), :at, :event)
                on conflict (tenant_id, id) do update set team_id = excluded.team_id, player_id = excluded.player_id,
                  jersey_number = excluded.jersey_number, joined_on = excluded.joined_on, left_on = excluded.left_on,
                  invalid_reason = excluded.invalid_reason, occurred_at = excluded.occurred_at,
                  event_id = excluded.event_id, updated_at = now()""", event, q -> q
                .setParameter("team", change.teamId().value())
                .setParameter("player", change.playerId().value())
                .setParameter("jersey", change.jerseyNumber().orElse(null))
                .setParameter("joined", change.joinedOn().toString())
                .setParameter("left", date(change.leftOn()))
                .setParameter("invalid", change.invalidReason().orElse(null)));
    }

    @Override
    public boolean teamStaff(RosterEvent event, TeamStaffChanged change) {
        return upsert("""
                insert into athlete.team_staff_ref as r (tenant_id, id, team_id, person_id, role, since, removed, occurred_at,
                  event_id)
                values (:tenant, :id, :team, :person, :role, cast(:since as date), false, :at, :event)
                on conflict (tenant_id, id) do update set team_id = excluded.team_id, person_id = excluded.person_id,
                  role = excluded.role, since = excluded.since, removed = false, occurred_at = excluded.occurred_at,
                  event_id = excluded.event_id, updated_at = now()""", event, q -> q
                .setParameter("team", change.teamId().value())
                .setParameter("person", change.personId().value())
                .setParameter("role", change.role())
                .setParameter("since", change.since().toString()));
    }

    @Override
    public boolean teamStaffRemoved(RosterEvent event, TeamStaffRemoved change) {
        return upsert("""
                insert into athlete.team_staff_ref as r (tenant_id, id, team_id, person_id, removed, occurred_at, event_id)
                values (:tenant, :id, :team, :person, true, :at, :event)
                on conflict (tenant_id, id) do update set removed = true, occurred_at = excluded.occurred_at,
                  event_id = excluded.event_id, updated_at = now()""", event, q -> q
                .setParameter("team", change.teamId().value())
                .setParameter("person", change.personId().value()));
    }

    @Override
    public boolean guardianLink(RosterEvent event, GuardianLinkChanged change) {
        return link(event, change.guardianPersonId().value(), change.playerId().value(), false);
    }

    @Override
    public boolean guardianLinkRemoved(RosterEvent event, GuardianLinkRemoved change) {
        return link(event, change.guardianPersonId().value(), change.playerId().value(), true);
    }

    private boolean link(RosterEvent event, UUID guardian, UUID player, boolean removed) {
        return upsert("""
                insert into athlete.guardian_link_ref as r (tenant_id, id, guardian_person_id, player_id, removed, occurred_at,
                  event_id)
                values (:tenant, :id, :guardian, :player, :removed, :at, :event)
                on conflict (tenant_id, id) do update set guardian_person_id = excluded.guardian_person_id,
                  player_id = excluded.player_id, removed = excluded.removed, occurred_at = excluded.occurred_at,
                  event_id = excluded.event_id, updated_at = now()""", event, q -> q
                .setParameter("guardian", guardian)
                .setParameter("player", player)
                .setParameter("removed", removed));
    }

    private boolean upsert(String sql, RosterEvent event, UnaryOperator<Query> parameters) {
        return parameters.apply(envelope(em.createNativeQuery(sql + NOT_NEWER), event)).executeUpdate() == 1;
    }

    private static Query envelope(Query query, RosterEvent event) {
        Query bound = query.setParameter("tenant", event.tenant().value())
                .setParameter("at", OffsetDateTime.ofInstant(event.occurredAt(), ZoneOffset.UTC))
                .setParameter("event", event.eventId());
        return hasParameter(bound, "id") ? bound.setParameter("id", event.aggregateId()) : bound;
    }

    private static boolean hasParameter(Query query, String name) {
        return query.getParameters().stream().anyMatch(p -> name.equals(p.getName()));
    }

    private static String date(Optional<LocalDate> date) {
        return date.map(LocalDate::toString).orElse(null);
    }
}
