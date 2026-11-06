package com.hoopsacademy.core.application.events;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.RosterStates;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The appender with in-memory states: what each change turns into (pure unit test, no container). */
class RosterEventAppenderTest {

    private static final TenantId TENANT = new TenantId(UUID.randomUUID());
    private static final LocalDate DAY = LocalDate.of(2026, 11, 6);

    private final FakeStates states = new FakeStates();
    private final List<OutboxEvent> written = new ArrayList<>();
    private final RosterEventAppender appender = new RosterEventAppender(states, written::add);

    @Test
    void aPersonWhoIsAPlayerIsFollowedByThePlayerAndEachAggregateIsWrittenOnce() {
        PersonId leo = new PersonId(UUID.randomUUID());
        PlayerId player = new PlayerId(UUID.randomUUID());
        states.persons.put(leo, new RosterStates.PersonState("Leo Kid", Optional.empty(),
                EnumSet.of(TenantRole.PLAYER, TenantRole.PARENT), true, Optional.of(player)));
        states.players.put(player, new RosterStates.PlayerState(leo, "Leo Kid", PlayerStatus.ACTIVE,
                Optional.of(DAY), Optional.of(Gender.MALE)));

        appender.append(TENANT, List.of(new RosterChange.Person(leo), new RosterChange.Person(leo),
                new RosterChange.Player(player)));

        assertThat(written).extracting(OutboxEvent::type).containsExactly("person.changed", "player.changed");
        OutboxEvent person = written.getFirst();
        assertThat(person.tenant()).isEqualTo(TENANT);
        assertThat(person.topic()).isEqualTo("core.person");
        assertThat(person.aggregateType()).isEqualTo("person");
        assertThat(person.aggregateId()).isEqualTo(leo.value().toString());
        assertThat(person.payload()).containsExactly(Map.entry("displayName", "Leo Kid"), entry("subject", null),
                Map.entry("roles", List.of("PARENT", "PLAYER")), Map.entry("active", true));
        assertThat(written.get(1).payload()).containsExactly(Map.entry("personId", leo.value().toString()),
                Map.entry("displayName", "Leo Kid"), Map.entry("status", "ACTIVE"),
                Map.entry("birthDate", "2026-11-06"), Map.entry("gender", "MALE"));
    }

    @Test
    void aSeasonRepublishesEachOfItsTeamsWithTheSeasonDates() {
        SeasonId season = new SeasonId(UUID.randomUUID());
        TeamId lions = new TeamId(UUID.randomUUID());
        TeamId cubs = new TeamId(UUID.randomUUID());
        AgeCategoryId u12 = new AgeCategoryId(UUID.randomUUID());
        states.seasons.put(season, List.of(lions, cubs));
        states.teams.put(lions, new RosterStates.TeamState(season, DAY, DAY.plusMonths(9), "Lions", Optional.of("L"),
                u12, GenderPolicy.MIXED));
        states.teams.put(cubs, new RosterStates.TeamState(season, DAY, DAY.plusMonths(9), "Cubs", Optional.empty(),
                u12, GenderPolicy.FEMALE));

        appender.append(TENANT, List.of(new RosterChange.Team(cubs), new RosterChange.Season(season)));

        assertThat(written).extracting(OutboxEvent::aggregateId).containsExactly(cubs.value().toString(),
                lions.value().toString());
        assertThat(written.getFirst().payload()).containsExactly(Map.entry("seasonId", season.value().toString()),
                Map.entry("seasonStartDate", "2026-11-06"), Map.entry("seasonEndDate", "2027-08-06"),
                Map.entry("name", "Cubs"), entry("alias", null), Map.entry("ageCategoryId", u12.value().toString()),
                Map.entry("genderPolicy", "FEMALE"));
        assertThat(written.get(1).payload()).containsEntry("alias", "L");
    }

    @Test
    void anAssignmentCarriesItsWholeState() {
        TeamPlayerId assignment = new TeamPlayerId(UUID.randomUUID());
        TeamId team = new TeamId(UUID.randomUUID());
        PlayerId player = new PlayerId(UUID.randomUUID());
        states.assignments.put(assignment, new RosterStates.TeamPlayerState(team, player, Optional.of("7"), DAY,
                Optional.of(DAY.plusDays(1)), 1, Optional.of(EligibilityReason.CATEGORY_TOO_LOW)));

        appender.append(TENANT, List.of(new RosterChange.TeamPlayer(assignment)));

        assertThat(written.getFirst().type()).isEqualTo("team-player.changed");
        assertThat(written.getFirst().payload()).containsExactly(Map.entry("teamId", team.value().toString()),
                Map.entry("playerId", player.value().toString()), Map.entry("jerseyNumber", "7"),
                Map.entry("joinedOn", "2026-11-06"), Map.entry("leftOn", "2026-11-07"), Map.entry("playUpLevels", 1),
                Map.entry("invalidReason", "CATEGORY_TOO_LOW"));
    }

    @Test
    void aStaffEntryIsChangedWhileItExistsAndRemovedWithItsIdentityOnceItIsGone() {
        TeamId team = new TeamId(UUID.randomUUID());
        PersonId coach = new PersonId(UUID.randomUUID());
        String id = EventTopic.teamStaffId(team.value(), coach.value()).toString();
        states.staff.put(List.of(team, coach), new RosterStates.TeamStaffState(StaffRole.COACH, DAY));

        appender.append(TENANT, List.of(new RosterChange.TeamStaff(team, coach)));
        states.staff.clear();
        appender.append(TENANT, List.of(new RosterChange.TeamStaff(team, coach)));

        assertThat(written).extracting(OutboxEvent::type).containsExactly("team-staff.changed", "team-staff.removed");
        assertThat(written).extracting(OutboxEvent::aggregateId).containsOnly(id);
        assertThat(written.getFirst().payload()).containsExactly(Map.entry("teamId", team.value().toString()),
                Map.entry("personId", coach.value().toString()), Map.entry("role", "COACH"),
                Map.entry("since", "2026-11-06"));
        assertThat(written.get(1).payload()).containsExactly(Map.entry("teamId", team.value().toString()),
                Map.entry("personId", coach.value().toString()));
    }

    @Test
    void aGuardianLinkIsRemovedWithTheEndsItHad() {
        GuardianLinkId link = new GuardianLinkId(UUID.randomUUID());
        PersonId pam = new PersonId(UUID.randomUUID());
        PlayerId kid = new PlayerId(UUID.randomUUID());
        states.links.put(link, new RosterStates.GuardianLinkState(pam, kid));

        appender.append(TENANT, List.of(new RosterChange.GuardianLink(link, pam, kid)));
        states.links.clear();
        appender.append(TENANT, List.of(new RosterChange.GuardianLink(link, pam, kid)));

        assertThat(written).extracting(OutboxEvent::type).containsExactly("guardian-link.changed",
                "guardian-link.removed");
        assertThat(written).extracting(OutboxEvent::payload).containsOnly(Map.of(
                "guardianPersonId", pam.value().toString(), "playerId", kid.value().toString()));
    }

    @Test
    void theTenantIsKeyedByItselfAndCarriesCodesNotEnumNames() {
        states.tenant = Optional.of(new RosterStates.TenantState("lions", "Lions", TenantStatus.SUSPENDED,
                ZoneId.of("Asia/Jakarta"), AppLocale.ID));

        appender.append(TENANT, List.of(new RosterChange.Tenant()));

        assertThat(written.getFirst().aggregateId()).isEqualTo(TENANT.value().toString());
        assertThat(written.getFirst().payload()).containsExactly(Map.entry("slug", "lions"), Map.entry("name", "Lions"),
                Map.entry("status", "SUSPENDED"), Map.entry("timezone", "Asia/Jakarta"), Map.entry("defaultLocale", "id"));
    }

    /** WP81 (decision 59): whatever deleted it, an aggregate reported changed but gone at commit is removed. */
    @Test
    void anAggregateThatIsGoneAtTheEndOfTheTransactionIsRemovedWithAnEmptyPayload() {
        PersonId person = new PersonId(UUID.randomUUID());
        PlayerId player = new PlayerId(UUID.randomUUID());
        TeamId team = new TeamId(UUID.randomUUID());
        TeamPlayerId assignment = new TeamPlayerId(UUID.randomUUID());

        appender.append(TENANT, List.of(new RosterChange.Person(person), new RosterChange.Player(player),
                new RosterChange.Team(team), new RosterChange.TeamPlayer(assignment), new RosterChange.Tenant()));

        assertThat(written).extracting(OutboxEvent::type).containsExactly("person.removed", "player.removed",
                "team.removed", "team-player.removed", "tenant.removed");
        assertThat(written).extracting(OutboxEvent::topic).containsExactly("core.person", "core.player", "core.team",
                "core.team-player", "core.tenant");
        assertThat(written).extracting(OutboxEvent::aggregateId).containsExactly(person.value().toString(),
                player.value().toString(), team.value().toString(), assignment.value().toString(),
                TENANT.value().toString());
        assertThat(written).extracting(OutboxEvent::aggregateType).containsExactly("person", "player", "team",
                "team-player", "tenant");
        assertThat(written).extracting(OutboxEvent::payload).containsOnly(Map.of());
        assertThat(written).extracting(OutboxEvent::tenant).containsOnly(TENANT);
    }

    @Test
    void thePlatformRemovesATenantWithAnEmptyPayloadKeyedByItself() {
        OutboxEvent event = TenantEvents.removed(TENANT);

        assertThat(event.topic()).isEqualTo("core.tenant");
        assertThat(event.type()).isEqualTo("tenant.removed");
        assertThat(event.tenant()).isEqualTo(TENANT);
        assertThat(event.aggregateType()).isEqualTo("tenant");
        assertThat(event.aggregateId()).isEqualTo(TENANT.value().toString());
        assertThat(event.payload()).isEmpty();
    }

    @Test
    void thePlatformsTenantEventHasTheSameShape() {
        var tenant = com.hoopsacademy.core.domain.tenant.Tenant.onboard(TENANT,
                new com.hoopsacademy.core.domain.tenant.TenantSlug("lions"), "Lions", ZoneId.of("Europe/Madrid"),
                AppLocale.ES, java.time.Instant.EPOCH).suspend("unpaid", java.time.Instant.EPOCH);

        OutboxEvent event = TenantEvents.changed(tenant);

        assertThat(event.topic()).isEqualTo("core.tenant");
        assertThat(event.type()).isEqualTo("tenant.changed");
        assertThat(event.aggregateId()).isEqualTo(TENANT.value().toString());
        assertThat(event.payload()).containsExactly(Map.entry("slug", "lions"), Map.entry("name", "Lions"),
                Map.entry("status", "SUSPENDED"), Map.entry("timezone", "Europe/Madrid"), Map.entry("defaultLocale", "es"));
    }

    private static Map.Entry<String, Object> entry(String key, Object value) {
        Map<String, Object> single = new LinkedHashMap<>();
        single.put(key, value);
        return single.entrySet().iterator().next();
    }

    private static final class FakeStates implements RosterStates {
        final Map<PersonId, PersonState> persons = new HashMap<>();
        final Map<PlayerId, PlayerState> players = new HashMap<>();
        final Map<TeamId, TeamState> teams = new HashMap<>();
        final Map<SeasonId, List<TeamId>> seasons = new HashMap<>();
        final Map<TeamPlayerId, TeamPlayerState> assignments = new HashMap<>();
        final Map<List<Object>, TeamStaffState> staff = new HashMap<>();
        final Map<GuardianLinkId, GuardianLinkState> links = new HashMap<>();
        Optional<TenantState> tenant = Optional.empty();

        @Override
        public Optional<PersonState> person(PersonId id) {
            return Optional.ofNullable(persons.get(id));
        }

        @Override
        public Optional<PlayerState> player(PlayerId id) {
            return Optional.ofNullable(players.get(id));
        }

        @Override
        public Optional<TeamState> team(TeamId id) {
            return Optional.ofNullable(teams.get(id));
        }

        @Override
        public List<TeamId> teamsOfSeason(SeasonId season) {
            return seasons.getOrDefault(season, List.of());
        }

        @Override
        public Optional<TeamPlayerState> teamPlayer(TeamPlayerId id) {
            return Optional.ofNullable(assignments.get(id));
        }

        @Override
        public Optional<TeamStaffState> teamStaff(TeamId team, PersonId person) {
            return Optional.ofNullable(staff.get(List.of(team, person)));
        }

        @Override
        public Optional<GuardianLinkState> guardianLink(GuardianLinkId id) {
            return Optional.ofNullable(links.get(id));
        }

        @Override
        public Optional<TenantState> tenant() {
            return tenant;
        }
    }
}
