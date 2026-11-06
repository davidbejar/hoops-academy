package com.hoopsacademy.athlete.adapters.in.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.adapters.out.persistence.ReplicaRosterRepository;
import com.hoopsacademy.athlete.application.PlayerBrief;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.CoreTopics;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.smallrye.reactive.messaging.kafka.KafkaClientService;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * Replay (ADR-0037, runbook "Replay the athlete replica"): with the replica emptied and the consumer group moved to the
 * start of the topics, the replica is rebuilt from the compacted topics alone and equals what it was before, including
 * removals, redeliveries and late older events in the stream.
 */
@QuarkusTest
@TestProfile(ReplicaProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class RosterReplayTest {

    static final Duration TIMEOUT = Duration.ofSeconds(60);
    static final List<String> REPLICA_TABLES = List.of("athlete.tenant_ref", "athlete.person_ref", "athlete.player_ref",
            "athlete.team_ref", "athlete.team_player_ref", "athlete.team_staff_ref", "athlete.guardian_link_ref",
            "athlete.applied_event");

    @Inject ReplicaRosterRepository replica;
    @Inject ReplicaAuthzResolver membership;
    @Inject TenantScope tenantScope;
    @Inject KafkaClientService kafka;

    /** What the replica answers for the fixture: the observable state a replay must restore. */
    record Snapshot(TeamRoster roster, Map<PlayerId, PlayerBrief> players, Optional<AuthzContext> coach,
            Optional<AuthzContext> parent) {}

    final TenantId tenant = TenantId.random();
    final UUID team = UUID.randomUUID();
    final UUID coach = UUID.randomUUID();
    final UUID parent = UUID.randomUUID();
    final List<UUID> players = List.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID());

    @Test
    void theReplicaEqualsTheFixtureAfterAReplayFromEmpty() {
        try (CoreTopics topics = new CoreTopics()) {
            publishFixture(topics);
        }
        CoreTopics.await("the fixture in the replica", TIMEOUT, () -> matchesFixture(snapshot()));
        Snapshot before = snapshot();

        empty();
        assertThatThrownBy(() -> inTenant(() -> replica.teamRoster(tenant, new TeamId(team))))
                .isInstanceOf(NotFoundException.class);
        replayFromTheStart();

        CoreTopics.await("the replica rebuilt from the topics", TIMEOUT, () -> snapshot().equals(before));
        assertThat(matchesFixture(snapshot())).isTrue();
    }

    private void publishFixture(CoreTopics topics) {
        LocalDate seasonEnd = LocalDate.now().plusMonths(6);
        CoreEvents.Record teamV1 = CoreEvents.team(tenant, team, "U14", seasonEnd);
        CoreEvents.Record teamV2 = CoreEvents.team(tenant, team, "U14 Lions", seasonEnd);
        topics.publish(CoreEvents.tenant(tenant, "ACTIVE", "Asia/Jakarta"), teamV1, teamV2, teamV1,
                teamV1.at(teamV2.occurredAt().minusSeconds(30)),
                CoreEvents.person(tenant, coach, "Cole Coach", "kc-" + coach, List.of("COACH"), true),
                CoreEvents.teamStaff(tenant, team, coach, "COACH"),
                CoreEvents.person(tenant, parent, "Pat Parent", "kc-" + parent, List.of("PARENT"), true));
        UUID removedCoach = UUID.randomUUID();
        CoreEvents.Record staffRemoved = CoreEvents.teamStaffRemoved(tenant, team, removedCoach);
        topics.publish(CoreEvents.teamStaff(tenant, team, removedCoach, "ASSISTANT_COACH"), staffRemoved)
                .tombstone(staffRemoved.topic(), staffRemoved.key());
        for (int i = 0; i < players.size(); i++) {
            UUID person = UUID.randomUUID();
            UUID assignment = UUID.randomUUID();
            topics.publish(CoreEvents.person(tenant, person, "Player " + i + "x", null, List.of("PLAYER"), true),
                    CoreEvents.player(tenant, players.get(i), person, "Player " + i + "x", "ACTIVE",
                            LocalDate.of(2012, 1, 1 + i), i % 2 == 0 ? "MALE" : "FEMALE"),
                    CoreEvents.teamPlayer(tenant, assignment, team, players.get(i), Integer.toString(i + 4),
                            LocalDate.of(2026, 9, 1 + i), null, null));
            if (i == 2) {
                topics.publish(CoreEvents.teamPlayer(tenant, assignment, team, players.get(i), null,
                        LocalDate.of(2026, 9, 1 + i), LocalDate.of(2026, 10, 1), null));
            }
        }
        UUID link = UUID.randomUUID();
        topics.publish(CoreEvents.guardianLink(tenant, link, parent, players.get(0)),
                CoreEvents.guardianLink(tenant, UUID.randomUUID(), parent, players.get(1)),
                CoreEvents.guardianLinkRemoved(tenant, link, parent, players.get(0)));
    }

    private boolean matchesFixture(Snapshot s) {
        return s.roster().teamName().equals("U14 Lions")
                && s.roster().playerIds().equals(List.of(new PlayerId(players.get(0)), new PlayerId(players.get(1))))
                && s.roster().staff().size() == 1 && s.roster().staff().get(0).value().equals(coach)
                && s.players().size() == 3
                && s.coach().map(c -> c.staffTeamIds().equals(java.util.Set.of(team))).orElse(false)
                && s.parent().map(p -> p.linkedPlayerIds().equals(java.util.Set.of(players.get(1)))
                        && p.playerTeamIds().equals(java.util.Set.of(team))).orElse(false);
    }

    private Snapshot snapshot() {
        return inTenant(() -> new Snapshot(replica.teamRoster(tenant, new TeamId(team)),
                replica.players(tenant, players.stream().map(PlayerId::new).toList()),
                membership.resolve("kc-" + coach, tenant), membership.resolve("kc-" + parent, tenant)));
    }

    private <T> T inTenant(java.util.function.Supplier<T> call) {
        return tenantScope.runAs(tenant, call);
    }

    /** The runbook empties the replica as athlete_migrator (truncate); here only this test's tenant is removed. */
    private void empty() {
        try (Connection c = RlsTestDatabase.fromConfig().openAsMigrator()) {
            c.setAutoCommit(false);
            try (PreparedStatement bind = c.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
                bind.setString(1, tenant.toString());
                bind.execute();
            }
            for (String table : REPLICA_TABLES) {
                try (PreparedStatement delete = c.prepareStatement("delete from " + table + " where tenant_id = ?")) {
                    delete.setObject(1, tenant.value());
                    delete.executeUpdate();
                }
            }
            c.commit();
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** What `rpk group seek athlete-service.roster --to start` does to a stopped consumer, on the running one. */
    private void replayFromTheStart() {
        kafka.getConsumer("core-roster")
                .runOnPollingThread(consumer -> {
                    consumer.seekToBeginning(consumer.assignment());
                    return null;
                })
                .await().atMost(Duration.ofSeconds(10));
    }
}
