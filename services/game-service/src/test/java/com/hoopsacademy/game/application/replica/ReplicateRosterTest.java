package com.hoopsacademy.game.application.replica;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder.Decoded;
import com.hoopsacademy.game.application.replica.ReplicateRoster.Outcome;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreEvents.Record;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.ReplicaDb;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Date;
import java.time.Instant;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Applying core's roster events to the replica (ADR-0037): one row per aggregate, a known event id changes nothing,
 * an older {@code occurredAt} never overwrites a newer one, removals are kept against older changes, and each event
 * is written in its own tenant whatever tenant the caller has bound.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class ReplicateRosterTest {

    private static final Instant T1 = Instant.parse("2026-11-06T10:00:00Z");
    private static final Instant T2 = Instant.parse("2026-11-06T11:00:00Z");
    private static final LocalDate SEASON_END = LocalDate.parse("2027-06-30");

    @Inject
    ReplicateRoster replicate;

    @Inject
    RosterEventDecoder decoder;

    @Inject
    TenantScope tenantScope;

    private TenantId tenant;
    private CoreEvents core;

    @BeforeEach
    void newTenant() {
        tenant = TenantId.random();
        core = CoreEvents.of(tenant);
    }

    @Test
    void aKnownEventIdChangesNothingEvenWithAnotherPayload() {
        UUID team = UUID.randomUUID();
        Record lions = core.team(team, UUID.randomUUID(), SEASON_END, "Lions");
        Record tigersWithTheSameId = new Record(lions.topic(), lions.key(), lions.value().replace("Lions", "Tigers"));

        assertThat(apply(lions)).isEqualTo(Outcome.APPLIED);
        assertThat(apply(lions)).isEqualTo(Outcome.DUPLICATE);
        assertThat(apply(tigersWithTheSameId)).isEqualTo(Outcome.DUPLICATE);

        assertThat(teamName(team)).isEqualTo("Lions");
        assertThat(ReplicaDb.value(tenant, "select count(*) from game.applied_event")).isEqualTo(1L);
    }

    @Test
    void anOlderEventNeverOverwritesANewerOne() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        Record newer = core.at(T2).team(team, season, SEASON_END, "Big Lions");
        Record older = core.at(T1).team(team, season, SEASON_END, "Lions");

        assertThat(apply(newer)).isEqualTo(Outcome.APPLIED);
        assertThat(apply(older)).isEqualTo(Outcome.STALE);

        assertThat(teamName(team)).isEqualTo("Big Lions");
        assertThat(apply(older)).as("a stale event is still a known event").isEqualTo(Outcome.DUPLICATE);
    }

    @Test
    void ofTwoEventsAtTheSameInstantTheLaterDeliveryWins() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        Record first = core.at(T1).team(team, season, SEASON_END, "Lions");
        Record second = core.at(T1).team(team, season, SEASON_END, "Big Lions");

        apply(first);

        assertThat(apply(second)).isEqualTo(Outcome.APPLIED);
        assertThat(teamName(team)).isEqualTo("Big Lions");
    }

    @Test
    void aRemovedStaffEntryStaysRemovedWhenAnOlderChangeArrivesLate() {
        UUID team = UUID.randomUUID();
        UUID coach = UUID.randomUUID();
        Record attached = core.at(T1).staff(team, coach, "COACH");
        Record detached = core.at(T2).staffRemoved(team, coach);

        assertThat(apply(detached)).isEqualTo(Outcome.APPLIED);
        assertThat(apply(attached)).isEqualTo(Outcome.STALE);

        assertThat(ReplicaDb.rows(tenant, "select team_id, person_id, removed from game.team_staff_ref"))
                .containsExactly(Map.of("team_id", team, "person_id", coach, "removed", true));
    }

    @Test
    void aStaffEntryAttachedAgainAfterItsRemovalCountsAgain() {
        UUID team = UUID.randomUUID();
        UUID coach = UUID.randomUUID();

        apply(core.staff(team, coach, "COACH"));
        apply(core.staffRemoved(team, coach));
        apply(core.staff(team, coach, "ASSISTANT_COACH"));

        assertThat(ReplicaDb.rows(tenant, "select role, removed from game.team_staff_ref"))
                .containsExactly(Map.of("role", "ASSISTANT_COACH", "removed", false));
    }

    @Test
    void guardianLinksAreChangedAndRemoved() {
        UUID link = UUID.randomUUID();
        UUID parent = UUID.randomUUID();
        UUID child = UUID.randomUUID();

        apply(core.link(link, parent, child));
        assertThat(ReplicaDb.rows(tenant, "select id, guardian_person_id, player_id, removed from game.guardian_link_ref"))
                .containsExactly(Map.of("id", link, "guardian_person_id", parent, "player_id", child, "removed", false));

        apply(core.linkRemoved(link, parent, child));
        assertThat(ReplicaDb.value(tenant, "select removed from game.guardian_link_ref")).isEqualTo(true);
    }

    @Test
    void aRemovalKeepsOnlyTheIdentityOfEveryAggregateAndALateOlderChangeCannotBringItBack() {
        UUID person = UUID.randomUUID();
        UUID player = UUID.randomUUID();
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        UUID assignment = UUID.randomUUID();
        Record tenantChanged = core.at(T1).tenant("ACTIVE", "Europe/Madrid");
        Record personChanged = core.person(person, "Ana Ruiz", "sub-ana", true, TenantRole.PLAYER);
        Record playerChanged = core.player(player, person, "Ana Ruiz", "ACTIVE", LocalDate.parse("2012-05-01"), "FEMALE");
        Record teamChanged = core.team(team, season, SEASON_END, "Lions");
        Record assignmentChanged = core.assignment(assignment, team, player, "7", LocalDate.parse("2026-09-01"), null,
                null);
        core.at(T2);

        for (Record removal : List.of(core.removed("person", person), core.removed("player", player),
                core.removed("team", team), core.removed("team-player", assignment), core.tenantRemoved())) {
            assertThat(apply(removal)).as(removal.topic()).isEqualTo(Outcome.APPLIED);
        }
        for (Record late : List.of(tenantChanged, personChanged, playerChanged, teamChanged, assignmentChanged)) {
            assertThat(apply(late)).as(late.topic()).isEqualTo(Outcome.STALE);
        }

        assertThat(ReplicaDb.rows(tenant, "select removed, status, timezone from game.tenant_ref")).containsExactly(
                nulls("removed", true, "status", "timezone"));
        assertThat(ReplicaDb.rows(tenant, "select removed, display_name, subject, roles, active from game.person_ref"))
                .containsExactly(nulls("removed", true, "display_name", "subject", "roles", "active"));
        assertThat(ReplicaDb.rows(tenant, "select removed, person_id, display_name, status, birth_date, gender "
                + "from game.player_ref")).containsExactly(
                        nulls("removed", true, "person_id", "display_name", "status", "birth_date", "gender"));
        assertThat(ReplicaDb.rows(tenant, "select removed, season_id, season_end_date, name from game.team_ref"))
                .containsExactly(nulls("removed", true, "season_id", "season_end_date", "name"));
        assertThat(ReplicaDb.rows(tenant, "select removed, team_id, player_id, jersey_number, joined_on "
                + "from game.team_player_ref")).containsExactly(
                        nulls("removed", true, "team_id", "player_id", "jersey_number", "joined_on"));
    }

    @Test
    void anAggregateChangedAfterItsRemovalIsBack() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();

        apply(core.team(team, season, SEASON_END, "Lions"));
        apply(core.removed("team", team));
        assertThat(apply(core.team(team, season, SEASON_END, "New Lions"))).isEqualTo(Outcome.APPLIED);

        assertThat(ReplicaDb.rows(tenant, "select removed, name from game.team_ref"))
                .containsExactly(Map.of("removed", false, "name", "New Lions"));
    }

    @Test
    void everyAggregateKeepsTheStateGameReads() {
        UUID person = UUID.randomUUID();
        UUID player = UUID.randomUUID();
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        UUID assignment = UUID.randomUUID();

        apply(core.tenant("ACTIVE", "Europe/Madrid"));
        apply(core.person(person, "Ana Ruiz", "sub-ana", true, TenantRole.PLAYER, TenantRole.PARENT));
        apply(core.player(player, person, "Ana Ruiz", "ACTIVE", LocalDate.parse("2012-05-01"), "FEMALE"));
        apply(core.team(team, season, SEASON_END, "Lions"));
        apply(core.assignment(assignment, team, player, "7", LocalDate.parse("2026-09-01"), null, null));

        assertThat(ReplicaDb.rows(tenant, "select status, timezone from game.tenant_ref"))
                .containsExactly(Map.of("status", "ACTIVE", "timezone", "Europe/Madrid"));
        assertThat(ReplicaDb.rows(tenant, "select display_name, subject, active, array_to_string(roles, ',') as roles "
                + "from game.person_ref")).containsExactly(
                        Map.of("display_name", "Ana Ruiz", "subject", "sub-ana", "active", true, "roles", "PARENT,PLAYER"));
        assertThat(ReplicaDb.rows(tenant, "select person_id, display_name, status, birth_date, gender from game.player_ref"))
                .containsExactly(Map.of("person_id", person, "display_name", "Ana Ruiz", "status", "ACTIVE",
                        "birth_date", Date.valueOf("2012-05-01"), "gender", "FEMALE"));
        assertThat(ReplicaDb.rows(tenant, "select season_id, season_end_date, name from game.team_ref"))
                .containsExactly(Map.of("season_id", season, "season_end_date", Date.valueOf(SEASON_END), "name", "Lions"));
        assertThat(ReplicaDb.rows(tenant, "select team_id, player_id, jersey_number, joined_on from game.team_player_ref"
                + " where left_on is null and invalid_reason is null")).containsExactly(Map.of("team_id", team,
                        "player_id", player, "jersey_number", "7", "joined_on", Date.valueOf("2026-09-01")));

        apply(core.tenant("SUSPENDED", "Asia/Jakarta"));
        apply(core.person(person, "Ana Ruiz-Gil", null, false, TenantRole.PLAYER));
        apply(core.player(player, person, "Ana Ruiz-Gil", "WITHDRAWN", null, null));
        apply(core.assignment(assignment, team, player, null, LocalDate.parse("2026-09-01"), LocalDate.parse("2026-10-01"),
                "PLAYER_NOT_ACTIVE"));

        assertThat(ReplicaDb.value(tenant, "select status || ' ' || timezone from game.tenant_ref"))
                .isEqualTo("SUSPENDED Asia/Jakarta");
        assertThat(ReplicaDb.value(tenant, "select display_name || ' ' || coalesce(subject, '-') || ' ' || active "
                + "from game.person_ref")).isEqualTo("Ana Ruiz-Gil - false");
        assertThat(ReplicaDb.value(tenant, "select status || ' ' || coalesce(gender, '-') || ' ' "
                + "|| coalesce(birth_date::text, '-') from game.player_ref")).isEqualTo("WITHDRAWN - -");
        assertThat(ReplicaDb.value(tenant, "select coalesce(jersey_number, '-') || ' ' || left_on || ' ' || invalid_reason "
                + "from game.team_player_ref")).isEqualTo("- 2026-10-01 PLAYER_NOT_ACTIVE");
    }

    @Test
    void anEventIsWrittenInItsOwnTenantNotInTheCallersTenant() {
        TenantId caller = TenantId.random();
        UUID team = UUID.randomUUID();
        Record lions = core.team(team, UUID.randomUUID(), SEASON_END, "Lions");

        tenantScope.runAs(caller, () -> apply(lions));

        assertThat(teamName(team)).isEqualTo("Lions");
        assertThat(ReplicaDb.value(caller, "select count(*) from game.team_ref")).isEqualTo(0L);
        assertThat(ReplicaDb.value(caller, "select count(*) from game.applied_event")).isEqualTo(0L);
    }

    @Test
    void theSameIdsInTwoTenantsAreTwoRows() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        TenantId other = TenantId.random();

        apply(core.team(team, season, SEASON_END, "Lions"));
        apply(CoreEvents.of(other).team(team, season, SEASON_END, "Tigers"));

        assertThat(teamName(team)).isEqualTo("Lions");
        assertThat(ReplicaDb.value(other, "select name from game.team_ref where id = '" + team + "'")).isEqualTo("Tigers");
    }

    @Test
    void aRejectedRecordIsParkedWithoutItsValue() {
        replicate.park(new ParkedRecord("core.team", 0, 42L, "k", Optional.of(UUID.randomUUID()), "schema violation: x"));

        List<Map<String, Object>> parked = ReplicaDb.parked();
        assertThat(parked).last().satisfies(row -> {
            assertThat(row).containsEntry("topic", "core.team").containsEntry("kafka_partition", 0)
                    .containsEntry("kafka_offset", 42L).containsEntry("record_key", "k")
                    .containsEntry("reason", "schema violation: x");
            assertThat(row.get("event_id")).isNotNull();
        });
    }

    /** A row with {@code flag} = {@code value} and every other column null. */
    private static Map<String, Object> nulls(String flag, Object value, String... columns) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put(flag, value);
        for (String column : columns) {
            row.put(column, null);
        }
        return row;
    }

    private Outcome apply(Record record) {
        Decoded decoded = decoder.decode(record.topic(), record.key(), record.value());
        assertThat(decoded).as("fixture records follow the contracts").isInstanceOf(Decoded.Valid.class);
        return replicate.apply(((Decoded.Valid) decoded).event());
    }

    private Object teamName(UUID team) {
        return ReplicaDb.value(tenant, "select name from game.team_ref where id = '" + team + "'");
    }
}
