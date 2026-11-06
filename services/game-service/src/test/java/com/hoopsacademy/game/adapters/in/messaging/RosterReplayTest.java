package com.hoopsacademy.game.adapters.in.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.application.PlayerBrief;
import com.hoopsacademy.game.application.TeamRoster;
import com.hoopsacademy.game.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.game.application.replica.ReplicaRosterPort;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreEvents.Record;
import com.hoopsacademy.game.support.CoreTopics;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.ReplicaDb;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.smallrye.reactive.messaging.kafka.KafkaClientService;
import io.smallrye.reactive.messaging.kafka.KafkaConsumer;
import jakarta.inject.Inject;
import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.Test;

/**
 * WP68 acceptance "replica equals core after replay from empty" (ADR-0037): a core fixture publishes an academy's
 * history through the WP67 contracts (changes, renames, a closed assignment, removals with tombstones, redeliveries,
 * a second academy); the live replica answers what core answers for the final state; then the replica is emptied and
 * the consumer group replays the topics from the start, and the rebuilt replica is row for row the same.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class RosterReplayTest {

    private static final Duration WAIT = Duration.ofSeconds(60);
    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    private static final LocalDate SEASON_END = LocalDate.now(ZONE).plusMonths(6);
    private static final LocalDate BORN = LocalDate.parse("2012-05-01");
    private static final LocalDate JOINED = LocalDate.parse("2026-09-01");

    @Inject
    KafkaClientService kafka;

    @Inject
    ReplicaRosterPort roster;

    @Inject
    ReplicaAuthzResolver authz;

    @Inject
    TenantScope tenantScope;

    private final TenantId academy = TenantId.random();
    private final TenantId otherAcademy = TenantId.random();
    private final UUID coach = UUID.randomUUID();
    private final UUID parent = UUID.randomUUID();
    private final UUID ana = UUID.randomUUID();
    private final UUID bea = UUID.randomUUID();
    private final UUID lions = UUID.randomUUID();
    private final UUID cubs = UUID.randomUUID();
    private final UUID season = UUID.randomUUID();

    @Test
    void theReplicaRebuiltFromTheTopicsIsTheSameAndAnswersWhatCoreAnswers() {
        CoreTopics.publish(history());
        await().atMost(WAIT).untilAsserted(this::answersWhatCoreAnswers);
        Map<String, List<Map<String, Object>>> live = snapshot();

        replayFromEmpty();

        await().atMost(WAIT).untilAsserted(() -> assertThat(snapshot()).isEqualTo(live));
        answersWhatCoreAnswers();
    }

    private Record[] history() {
        CoreEvents core = CoreEvents.of(academy);
        UUID anaAssignment = UUID.randomUUID();
        UUID beaLink = UUID.randomUUID();
        Record lionsCreated = core.team(lions, season, SEASON_END, "Lions");
        Record cubsStaffRemoved = core.staffRemoved(cubs, coach);
        Record beaUnlinked = core.linkRemoved(beaLink, parent, bea);
        CoreEvents other = CoreEvents.of(otherAcademy);
        List<Record> records = new ArrayList<>(List.of(
                core.tenant("ACTIVE", "UTC"),
                core.person(coach, "Cora Coach", "sub-cora-" + coach, true, TenantRole.COACH),
                core.person(parent, "Paula Parent", "sub-paula-" + parent, true, TenantRole.PARENT),
                lionsCreated, lionsCreated,
                core.team(cubs, season, SEASON_END, "Cubs"),
                core.player(ana, UUID.randomUUID(), "Ana Ruiz", "PENDING_APPROVAL", BORN, "FEMALE"),
                core.player(bea, UUID.randomUUID(), "Bea Gil", "ACTIVE", BORN, "FEMALE"),
                core.player(ana, UUID.randomUUID(), "Ana Ruiz-Gil", "ACTIVE", BORN, "FEMALE"),
                core.assignment(anaAssignment, lions, ana, "7", JOINED, null, null),
                core.assignment(UUID.randomUUID(), lions, bea, "4", JOINED, LocalDate.parse("2026-10-01"), null),
                core.staff(lions, coach, "COACH"), core.staff(cubs, coach, "COACH"),
                core.link(UUID.randomUUID(), parent, ana), core.link(beaLink, parent, bea),
                core.team(lions, season, SEASON_END, "Big Lions"),
                core.assignment(anaAssignment, lions, ana, "8", JOINED, null, null),
                cubsStaffRemoved, CoreEvents.tombstone(cubsStaffRemoved), beaUnlinked, beaUnlinked,
                CoreEvents.tombstone(beaUnlinked),
                core.tenant("ACTIVE", ZONE.getId()),
                other.tenant("ACTIVE", "Asia/Jakarta"), other.team(lions, season, SEASON_END, "Jakarta Lions"),
                other.player(ana, UUID.randomUUID(), "Ani Other", "ACTIVE", BORN, "FEMALE")));
        return records.toArray(Record[]::new);
    }

    private void answersWhatCoreAnswers() {
        assertThat(inTenant(academy, () -> roster.teamRoster(academy, TeamId.of(lions)))).isEqualTo(new TeamRoster(
                TeamId.of(lions), SeasonId.of(season), "Big Lions",
                List.of(new TeamRoster.Player(PlayerId.of(ana), "Ana Ruiz-Gil", "8"))));
        assertThat(inTenant(academy, () -> roster.teamRoster(academy, TeamId.of(cubs))).players()).isEmpty();
        assertThat(inTenant(academy, () -> roster.players(academy, List.of(PlayerId.of(ana), PlayerId.of(bea)))))
                .containsExactlyInAnyOrder(new PlayerBrief(PlayerId.of(ana), "Ana Ruiz-Gil"),
                        new PlayerBrief(PlayerId.of(bea), "Bea Gil"));
        assertThat(inTenant(academy, () -> authz.resolve("sub-cora-" + coach, academy))).contains(new AuthzContext(
                "sub-cora-" + coach, coach, academy, Set.of(TenantRole.COACH), Set.of(lions), Set.of(), Optional.empty(),
                Set.of(), Optional.of(ZONE)));
        assertThat(inTenant(academy, () -> authz.resolve("sub-paula-" + parent, academy))).contains(new AuthzContext(
                "sub-paula-" + parent, parent, academy, Set.of(TenantRole.PARENT), Set.of(), Set.of(ana),
                Optional.empty(), Set.of(lions), Optional.of(ZONE)));
        assertThat(inTenant(otherAcademy, () -> roster.teamRoster(otherAcademy, TeamId.of(lions))).teamName())
                .isEqualTo("Jakarta Lions");
        assertThat(inTenant(otherAcademy, () -> roster.players(otherAcademy, List.of(PlayerId.of(ana)))))
                .containsExactly(new PlayerBrief(PlayerId.of(ana), "Ani Other"));
    }

    /** What the operator does (docs/runbooks/events.md): empty the replica, move the group to the topics' start. */
    private void replayFromEmpty() {
        ReplicaDb.truncate();
        KafkaConsumer<Object, Object> consumer = kafka.getConsumer("core-roster");
        Set<TopicPartition> partitions = consumer.getAssignments().await().atMost(WAIT);
        assertThat(partitions).extracting(TopicPartition::topic).contains("core.person", "core.player", "core.team",
                "core.team-player", "core.team-staff", "core.guardian-link", "core.tenant");
        consumer.seekToBeginning(partitions).await().atMost(WAIT);
    }

    /** Every replica row of both academies (applied_event without its local timestamp). */
    private Map<String, List<Map<String, Object>>> snapshot() {
        Map<String, List<Map<String, Object>>> rows = new LinkedHashMap<>();
        for (TenantId tenant : List.of(academy, otherAcademy)) {
            for (String table : ReplicaDb.TABLES) {
                String columns = table.equals("game.applied_event") ? "event_id, topic" : "*";
                String order = table.equals("game.applied_event") ? "event_id" : "1, 2";
                rows.put(tenant + " " + table, ReplicaDb.rows(tenant,
                        "select " + columns + " from " + table + " order by " + order));
            }
        }
        return rows;
    }

    private <T> T inTenant(TenantId tenant, Supplier<T> call) {
        return tenantScope.runAs(tenant, call);
    }
}
