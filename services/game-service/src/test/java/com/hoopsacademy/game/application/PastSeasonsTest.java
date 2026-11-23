package com.hoopsacademy.game.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.SeasonEndedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * When a team's season closed (ADR-0042), read from the team alone: never through its roster (GAME-03, WP126).
 */
class PastSeasonsTest {

    private static final TenantId TENANT = TenantId.random();
    private static final TeamId TEAM = TeamId.of(UUID.randomUUID());
    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");
    private static final Instant NOW = Instant.parse("2027-07-01T12:00:00Z");

    private final RosterPort roster = mock(RosterPort.class);
    private final CurrentCaller caller = mock(CurrentCaller.class);
    private final PastSeasons pastSeasons = new PastSeasons(roster, caller, Clock.fixed(NOW, ZoneOffset.UTC));

    @Test
    void anEndedSeasonClosedAtTheStartOfTheNextDayInTheAcademysZone() {
        callerIs(admin(Optional.of(MADRID)));
        seasonEnds(LocalDate.parse("2027-06-30"));

        assertThat(pastSeasons.closedSince(TEAM)).contains(Instant.parse("2027-06-30T22:00:00Z"));
        assertThatThrownBy(() -> pastSeasons.requireOpen(TEAM)).isInstanceOf(SeasonEndedException.class);
        verify(roster, never()).teamRoster(any(), any());
    }

    @Test
    void aSeasonEndingTodayIsOpen() {
        callerIs(admin(Optional.empty()));
        seasonEnds(LocalDate.parse("2027-07-01"));

        assertThat(pastSeasons.closedSince(TEAM)).isEmpty();
        pastSeasons.requireOpen(TEAM);
    }

    @Test
    void aTeamWithoutSeasonEndOrUnknownIsOpen() {
        callerIs(admin(Optional.of(MADRID)));
        seasonEnds(null);
        assertThat(pastSeasons.closedSince(TEAM)).isEmpty();

        when(roster.team(TENANT, TEAM)).thenThrow(new NotFoundException("Team not found"));
        assertThat(pastSeasons.closedSince(TEAM)).isEmpty();
    }

    @Test
    void currentStaffNeedNoLookup() {
        callerIs(new AuthzContext("coach", UUID.randomUUID(), TENANT, Set.of(TenantRole.COACH), Set.of(TEAM.value()),
                Set.of(), Optional.empty(), Set.of(), Optional.of(MADRID)));

        assertThat(pastSeasons.closedSince(TEAM)).isEmpty();
        verifyNoInteractions(roster);
    }

    private void callerIs(AuthzContext authz) {
        when(caller.authz()).thenReturn(authz);
        when(caller.tenantId()).thenReturn(TENANT);
    }

    private void seasonEnds(LocalDate lastDay) {
        when(roster.team(TENANT, TEAM)).thenReturn(new TeamBrief(TEAM, SeasonId.of(UUID.randomUUID()), "Lions", lastDay));
    }

    private static AuthzContext admin(Optional<ZoneId> zone) {
        return new AuthzContext("admin", UUID.randomUUID(), TENANT, Set.of(TenantRole.ADMIN), Set.of(), Set.of(),
                Optional.empty(), Set.of(), zone);
    }
}
