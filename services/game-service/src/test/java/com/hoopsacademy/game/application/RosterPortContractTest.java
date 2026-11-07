package com.hoopsacademy.game.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder;
import com.hoopsacademy.game.adapters.out.client.RestRosterPort;
import com.hoopsacademy.game.application.replica.ReplicaRosterPort;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import com.hoopsacademy.game.support.CoreAnswers;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreEvents.Record;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import com.hoopsacademy.game.support.ReplicaFeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

/**
 * The {@link RosterPort} contract (ADR-0037), the same cases against both adapters: REST (WireMock answering what core
 * answers for the state) and the replica (the state arrives as core's events). The transport details of the REST
 * adapter (token, cache, timeouts) stay in {@code RestRosterPortTest}.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class RosterPortContractTest {

    enum Source {
        REST,
        REPLICA
    }

    private static final LocalDate SEASON_END = LocalDate.now().plusMonths(6);
    private static final LocalDate BORN = LocalDate.parse("2012-05-01");

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RestRosterPort rest;

    @Inject
    ReplicaRosterPort replica;

    @Inject
    RosterEventDecoder decoder;

    @Inject
    ReplicateRoster replicate;

    @Inject
    TenantScope tenantScope;

    private TenantId tenant;
    private CoreEvents events;
    private UUID team;
    private UUID season;

    @BeforeEach
    void activeTenantWithATeam() {
        CoreStubs.reset(core);
        rest.clearCache();
        tenant = TenantId.random();
        events = CoreEvents.of(tenant);
        team = UUID.randomUUID();
        season = UUID.randomUUID();
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void theRosterListsOpenValidAssignmentsOfCompletePlayersInJoiningOrder(Source source) {
        UUID ana = UUID.randomUUID();
        UUID bea = UUID.randomUUID();
        UUID carl = UUID.randomUUID();
        UUID dan = UUID.randomUUID();
        UUID eve = UUID.randomUUID();
        UUID fay = UUID.randomUUID();
        UUID gus = UUID.randomUUID();
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), lions(),
                player(ana, "Ana Ruiz", BORN, "FEMALE"), player(bea, "Bea Gil", BORN, "FEMALE"),
                player(carl, "Carl Left", BORN, "MALE"), player(dan, "Dan Invalid", BORN, "MALE"),
                player(eve, "Eve Nobirth", null, "FEMALE"), player(fay, "Fay Nogender", BORN, null),
                player(gus, "Gus Elsewhere", BORN, "MALE"),
                events.assignment(UUID.randomUUID(), team, ana, "7", LocalDate.parse("2026-09-02"), null, null),
                events.assignment(UUID.randomUUID(), team, bea, null, LocalDate.parse("2026-09-01"), null, null),
                events.assignment(UUID.randomUUID(), team, carl, "9", LocalDate.parse("2026-09-01"),
                        LocalDate.parse("2026-10-01"), null),
                events.assignment(UUID.randomUUID(), team, dan, "10", LocalDate.parse("2026-09-01"), null,
                        "CATEGORY_TOO_LOW"),
                events.assignment(UUID.randomUUID(), team, eve, "11", LocalDate.parse("2026-09-01"), null, null),
                events.assignment(UUID.randomUUID(), team, fay, "12", LocalDate.parse("2026-09-01"), null, null),
                events.assignment(UUID.randomUUID(), UUID.randomUUID(), gus, "13", LocalDate.parse("2026-09-01"), null,
                        null));
        TeamRoster expected = new TeamRoster(TeamId.of(team), SeasonId.of(season), "Lions", List.of(
                new TeamRoster.Player(PlayerId.of(bea), "Bea Gil", null),
                new TeamRoster.Player(PlayerId.of(ana), "Ana Ruiz", "7")), SEASON_END);
        coreAnswers(source, () -> CoreAnswers.teamRoster(core, tenant, expected));

        assertThat(inTenant(() -> port(source).teamRoster(tenant, TeamId.of(team)))).isEqualTo(expected);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void theRosterFollowsTheLatestState(Source source) {
        UUID ana = UUID.randomUUID();
        UUID assignment = UUID.randomUUID();
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), lions(), player(ana, "Ana Ruiz", BORN, "FEMALE"),
                events.assignment(assignment, team, ana, "7", LocalDate.parse("2026-09-01"), null, null),
                events.team(team, season, SEASON_END.plusDays(1), "Big Lions"),
                player(ana, "Ana Ruiz-Gil", BORN, "FEMALE"),
                events.assignment(assignment, team, ana, "8", LocalDate.parse("2026-09-01"), null, null));
        TeamRoster expected = new TeamRoster(TeamId.of(team), SeasonId.of(season), "Big Lions",
                List.of(new TeamRoster.Player(PlayerId.of(ana), "Ana Ruiz-Gil", "8")), SEASON_END.plusDays(1));
        coreAnswers(source, () -> CoreAnswers.teamRoster(core, tenant, expected));

        assertThat(inTenant(() -> port(source).teamRoster(tenant, TeamId.of(team)))).isEqualTo(expected);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void anUnknownTeamIsNotFound(Source source) {
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), lions());
        UUID unknown = UUID.randomUUID();
        coreAnswers(source, () -> CoreAnswers.teamNotFound(core, unknown));

        assertThatThrownBy(() -> inTenant(() -> port(source).teamRoster(tenant, TeamId.of(unknown))))
                .isInstanceOf(NotFoundException.class);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aSuspendedTenantHasNoRosterAndNoPlayers(Source source) {
        UUID ana = UUID.randomUUID();
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), lions(), player(ana, "Ana Ruiz", BORN, "FEMALE"),
                events.tenant("SUSPENDED", "Europe/Madrid"));
        coreAnswers(source, () -> {
            CoreAnswers.teamNotFound(core, team);
            CoreAnswers.playersNotFound(core);
        });

        assertThatThrownBy(() -> inTenant(() -> port(source).teamRoster(tenant, TeamId.of(team))))
                .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> inTenant(() -> port(source).players(tenant, List.of(PlayerId.of(ana)))))
                .isInstanceOf(NotFoundException.class);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aTenantCoreNeverReportedIsNotFound(Source source) {
        given(source, lions());
        coreAnswers(source, () -> CoreAnswers.teamNotFound(core, team));

        assertThatThrownBy(() -> inTenant(() -> port(source).teamRoster(tenant, TeamId.of(team))))
                .isInstanceOf(NotFoundException.class);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void playersAnswersTheKnownCompletePlayersOnce(Source source) {
        UUID ana = UUID.randomUUID();
        UUID eve = UUID.randomUUID();
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), player(ana, "Ana Ruiz", BORN, "FEMALE"),
                player(eve, "Eve Nobirth", null, "FEMALE"));
        List<PlayerBrief> expected = List.of(new PlayerBrief(PlayerId.of(ana), "Ana Ruiz"));
        coreAnswers(source, () -> CoreAnswers.players(core, tenant, expected));

        List<PlayerBrief> answer = inTenant(() -> port(source).players(tenant,
                List.of(PlayerId.of(ana), PlayerId.of(UUID.randomUUID()), PlayerId.of(eve), PlayerId.of(ana))));

        assertThat(answer).containsExactlyElementsOf(expected);
        assertThat(inTenant(() -> port(source).players(tenant, List.of()))).isEmpty();
    }

    /** WP82: removed players and assignments leave the roster, a removed team or tenant is not found, as in core. */
    @ParameterizedTest
    @EnumSource(Source.class)
    void removedPlayersAndAssignmentsLeaveTheRoster(Source source) {
        UUID ana = UUID.randomUUID();
        UUID bea = UUID.randomUUID();
        UUID carl = UUID.randomUUID();
        UUID beasAssignment = UUID.randomUUID();
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), lions(), player(ana, "Ana Ruiz", BORN, "FEMALE"),
                player(bea, "Bea Gil", BORN, "FEMALE"), player(carl, "Carl Gone", BORN, "MALE"),
                events.assignment(UUID.randomUUID(), team, ana, "7", LocalDate.parse("2026-09-01"), null, null),
                events.assignment(beasAssignment, team, bea, "8", LocalDate.parse("2026-09-01"), null, null),
                events.assignment(UUID.randomUUID(), team, carl, "9", LocalDate.parse("2026-09-01"), null, null),
                events.removed("team-player", beasAssignment), events.removed("player", carl));
        TeamRoster expected = new TeamRoster(TeamId.of(team), SeasonId.of(season), "Lions",
                List.of(new TeamRoster.Player(PlayerId.of(ana), "Ana Ruiz", "7")), SEASON_END);
        List<PlayerBrief> briefs = List.of(new PlayerBrief(PlayerId.of(bea), "Bea Gil"));
        coreAnswers(source, () -> {
            CoreAnswers.teamRoster(core, tenant, expected);
            CoreAnswers.players(core, tenant, briefs);
        });

        assertThat(inTenant(() -> port(source).teamRoster(tenant, TeamId.of(team)))).isEqualTo(expected);
        assertThat(inTenant(() -> port(source).players(tenant, List.of(PlayerId.of(bea), PlayerId.of(carl)))))
                .containsExactlyElementsOf(briefs);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aRemovedTeamIsNotFound(Source source) {
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), lions(), events.removed("team", team));
        coreAnswers(source, () -> CoreAnswers.teamNotFound(core, team));

        assertThatThrownBy(() -> inTenant(() -> port(source).teamRoster(tenant, TeamId.of(team))))
                .isInstanceOf(NotFoundException.class);
    }

    @ParameterizedTest
    @EnumSource(Source.class)
    void aRemovedTenantHasNoRosterAndNoPlayers(Source source) {
        UUID ana = UUID.randomUUID();
        given(source, events.tenant("ACTIVE", "Europe/Madrid"), lions(), player(ana, "Ana Ruiz", BORN, "FEMALE"),
                events.tenantRemoved());
        coreAnswers(source, () -> {
            CoreAnswers.teamNotFound(core, team);
            CoreAnswers.playersNotFound(core);
        });

        assertThatThrownBy(() -> inTenant(() -> port(source).teamRoster(tenant, TeamId.of(team))))
                .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> inTenant(() -> port(source).players(tenant, List.of(PlayerId.of(ana)))))
                .isInstanceOf(NotFoundException.class);
    }

    private Record lions() {
        return events.team(team, season, SEASON_END, "Lions");
    }

    private Record player(UUID id, String name, LocalDate birthDate, String gender) {
        return events.player(id, UUID.nameUUIDFromBytes(id.toString().getBytes()), name, "ACTIVE", birthDate, gender);
    }

    private void given(Source source, Record... records) {
        if (source == Source.REPLICA) {
            ReplicaFeed.apply(decoder, replicate, records);
        }
    }

    private void coreAnswers(Source source, Runnable stubs) {
        if (source == Source.REST) {
            stubs.run();
        }
    }

    private RosterPort port(Source source) {
        return source == Source.REST ? rest : replica;
    }

    private <T> T inTenant(Supplier<T> call) {
        return tenantScope.runAs(tenant, call);
    }
}
