package com.hoopsacademy.core.application.authz;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.testing.MembershipRuleContract;
import com.hoopsacademy.common.testing.MembershipWorld;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.time.Duration;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * The membership rule table (ADR-0066) against core's tenant filter path: {@link CoreAuthzContextResolver} over
 * {@link MembershipLookup}, with core's repositories answering what the world holds.
 */
class MembershipLookupRuleTest extends MembershipRuleContract {

    @Override
    protected Optional<AuthzContext> resolve(MembershipWorld world) {
        TenantContext tenantContext = mock(TenantContext.class);
        when(tenantContext.requireTenantId()).thenReturn(MembershipWorld.TENANT);
        TenantProfileRepository profiles = mock(TenantProfileRepository.class);
        when(profiles.findCurrent()).thenReturn(world.tenantStatus().map(status -> new TenantProfile(
                MembershipWorld.TENANT, "academy", "Academy", MembershipWorld.ZONE, AppLocale.EN, null, null,
                TenantStatus.valueOf(status.name()))));
        PersonRepository persons = mock(PersonRepository.class);
        when(persons.findActiveByLogin(MembershipWorld.SUBJECT)).thenReturn(world.memberRoles().map(roles -> new Person(
                new PersonId(MembershipWorld.PERSON), null, new PersonalData("Mia", "Member", null, null,
                        LocalDate.parse("2010-01-01"), Gender.FEMALE, AppLocale.EN),
                roles, true, null, null, null)));
        PlayerRepository players = mock(PlayerRepository.class);
        when(players.findByPerson(new PersonId(MembershipWorld.PERSON)))
                .thenReturn(world.ownPlayer().map(PlayerId::new));
        GuardianLinkRepository links = mock(GuardianLinkRepository.class);
        when(links.playersOf(new PersonId(MembershipWorld.PERSON))).thenReturn(
                world.guardedPlayers().stream().map(PlayerId::new).collect(Collectors.toSet()));
        TeamStaffRepository staff = mock(TeamStaffRepository.class);
        when(staff.teamsOf(new PersonId(MembershipWorld.PERSON))).thenReturn(
                world.staffTeams().stream().map(TeamId::new).collect(Collectors.toSet()));
        TeamPlayerRepository assignments = mock(TeamPlayerRepository.class);
        when(assignments.openOfPlayers(anyCollection())).thenAnswer(call -> {
            Collection<PlayerId> asked = call.getArgument(0);
            return asked.stream().flatMap(player -> world.openValidTeamsOf(player.value()).stream()
                    .map(team -> TeamPlayer.assign(new TeamId(team), player, null, LocalDate.parse("2026-09-01"), 0)))
                    .toList();
        });
        TeamRepository teams = mock(TeamRepository.class);
        when(teams.seasonNotEnded(anyCollection(), any())).thenAnswer(call -> {
            Collection<TeamId> asked = call.getArgument(0);
            LocalDate today = call.getArgument(1);
            return asked.stream().filter(team -> world.seasonEnd(team.value()).filter(end -> !end.isBefore(today))
                    .isPresent()).collect(Collectors.toSet());
        });
        MembershipLookup lookup = new MembershipLookup(tenantContext, profiles, persons, players, links, staff,
                assignments, teams, MembershipWorld.CLOCK);
        return new CoreAuthzContextResolver(lookup, new AuthzCache(Duration.ofSeconds(10), MembershipWorld.CLOCK))
                .resolve(MembershipWorld.SUBJECT, MembershipWorld.TENANT);
    }

    /**
     * Difference 1 of ADR-0066: core counted every staff team not "not ended" as ended, so a staff row of a team it
     * does not know became history. Unreachable in core (team_staff has a foreign key to team).
     */
    @Override
    protected Optional<AuthzContext> expected(MembershipCase row) {
        if (row.name().equals(UNKNOWN_STAFF_TEAM)) {
            return row.expected().map(context -> context.withHistoricStaffTeamIds(Set.of(MembershipWorld.UNKNOWN_TEAM)));
        }
        return row.expected();
    }
}
