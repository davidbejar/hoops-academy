package com.hoopsacademy.core.application.roster;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.application.roster.RolloverSeason.RolloverCommand;
import com.hoopsacademy.core.application.roster.RolloverSeason.RolloverResult;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/**
 * CORE-02 as corrected by the verification (audit 2026-11-23): a rollover reads the open assignments, the staff and the
 * players of all source teams with one query each, instead of three reads per source team.
 */
class RolloverReadsTest {

    private static final LocalDate TODAY = LocalDate.of(2027, 6, 1);
    private static final Season SOURCE = new Season(SeasonId.random(), "2026/27", LocalDate.of(2026, 9, 1),
            LocalDate.of(2027, 6, 30), 2026);
    private static final Season TARGET = new Season(SeasonId.random(), "2027/28", LocalDate.of(2027, 9, 1),
            LocalDate.of(2028, 6, 30), 2027);

    private final SeasonRepository seasons = mock(SeasonRepository.class);
    private final TeamRepository teams = mock(TeamRepository.class);
    private final TeamStaffRepository staff = mock(TeamStaffRepository.class);
    private final TeamPlayerRepository assignments = mock(TeamPlayerRepository.class);
    private final PlayerRepository players = mock(PlayerRepository.class);
    private final TenantToday calendar = mock(TenantToday.class);
    private final TenantContext tenantContext = mock(TenantContext.class);
    private final RolloverSeason rollover = new RolloverSeason(tenantContext, seasons, teams, staff, assignments,
            players, mock(EligibilityEngine.class), mock(PlayerStatusSync.class), mock(AuthzCache.class), calendar);

    private final Team first = team("A Team");
    private final Team second = team("B Team");

    @Test
    void readsTheAssignmentsStaffAndPlayersOfAllSourceTeamsOnce() {
        PlayerSummary shared = player("Leo");
        PlayerSummary onlySecond = player("Eva");
        TeamPlayer firstOfShared = TeamPlayer.assign(first.id(), shared.id(), null, SOURCE.startsOn(), 0);
        TeamPlayer secondOfShared = TeamPlayer.assign(second.id(), shared.id(), null, SOURCE.startsOn(), 0);
        TeamPlayer secondOfEva = TeamPlayer.assign(second.id(), onlySecond.id(), null, SOURCE.startsOn(), 0);
        TeamStaffMember coach = new TeamStaffMember(second.id(), PersonId.random(), StaffRole.COACH,
                SOURCE.startsOn());
        arrange(List.of(firstOfShared, secondOfShared, secondOfEva), List.of(coach),
                Map.of(shared.id(), shared, onlySecond.id(), onlySecond));

        RolloverResult result = rollover.rollover(TARGET.id(), new RolloverCommand(SOURCE.id(), true, false));

        verify(assignments, never()).ofTeam(any(), anyBoolean());
        verify(staff, never()).ofTeam(any());
        verify(assignments, times(1)).openOfTeams(anyCollection());
        verify(staff, times(1)).ofTeams(anyCollection());
        verify(players, times(1)).summaries(anyCollection());
        assertThat(result.clonedTeams()).extracting(Team::name).containsExactly("A Team", "B Team");
        assertThat(result.orphans()).as("not carried over: every active player is an orphan of its first team")
                .extracting(orphan -> orphan.displayName(), orphan -> orphan.previousTeam().name())
                .containsExactly(org.assertj.core.groups.Tuple.tuple("Leo Ruiz", "A Team"),
                        org.assertj.core.groups.Tuple.tuple("Eva Ruiz", "B Team"));
        ArgumentCaptor<TeamStaffMember> cloned = ArgumentCaptor.forClass(TeamStaffMember.class);
        verify(staff).save(cloned.capture());
        assertThat(cloned.getValue().team()).isEqualTo(result.clonedTeams().get(1).id());
        assertThat(cloned.getValue().since()).isEqualTo(TODAY);
    }

    @Test
    void withoutStaffCloningTheStaffIsNotRead() {
        arrange(List.of(), List.of(), Map.of());

        rollover.rollover(TARGET.id(), new RolloverCommand(SOURCE.id(), false, true));

        verify(staff, never()).ofTeams(anyCollection());
        verify(staff, never()).save(any());
    }

    private void arrange(List<TeamPlayer> open, List<TeamStaffMember> members, Map<PlayerId, PlayerSummary> found) {
        when(tenantContext.requireTenantId()).thenReturn(TenantId.random());
        when(calendar.today()).thenReturn(TODAY);
        when(seasons.require(SOURCE.id())).thenReturn(SOURCE);
        when(seasons.require(TARGET.id())).thenReturn(TARGET);
        when(teams.inSeasons(List.of(TARGET.id()))).thenReturn(List.of());
        when(teams.inSeasons(List.of(SOURCE.id()))).thenReturn(List.of(first, second));
        when(assignments.openOfTeams(anyCollection())).thenReturn(open);
        when(staff.ofTeams(anyCollection())).thenReturn(members);
        when(players.summaries(anyCollection())).thenReturn(found);
    }

    private static Team team(String name) {
        return new Team(TeamId.random(), SOURCE.id(), name, null, AgeCategoryId.random(), GenderPolicy.MIXED);
    }

    private static PlayerSummary player(String given) {
        return new PlayerSummary(PlayerId.random(), PersonId.random(), given + " Ruiz", PlayerStatus.ACTIVE,
                LocalDate.of(2014, 3, 1), Gender.FEMALE, given, "Ruiz", null);
    }
}
