package com.hoopsacademy.athlete.application.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent.Outcome;
import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.PersonChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.PlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamPlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.TenantChanged;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * How one roster event reaches the replica, without a database (PIT scope, WP88): in the event's tenant, a known id
 * changes nothing, each change goes to its own store write, and only a written tenant event refreshes the registry.
 */
class ApplyRosterEventRulesTest {

    private static final TenantId TENANT = TenantId.random();
    private static final ZoneId JAKARTA = ZoneId.of("Asia/Jakarta");
    private static final PersonId PERSON = new PersonId(UUID.randomUUID());
    private static final PlayerId PLAYER = new PlayerId(UUID.randomUUID());
    private static final TeamId TEAM = new TeamId(UUID.randomUUID());
    private static final LocalDate DAY = LocalDate.of(2026, 11, 7);

    private final TenantScope tenantScope = mock(TenantScope.class);
    private final RosterReplicaStore store = mock(RosterReplicaStore.class);
    private final TenantRegistry registry = mock(TenantRegistry.class);
    private final ApplyRosterEvent apply = new ApplyRosterEvent(tenantScope, store, registry);
    private final List<TenantId> entered = new ArrayList<>();

    @BeforeEach
    @SuppressWarnings("unchecked")
    void tenantScopeRunsTheWork() {
        when(tenantScope.runAs(any(TenantId.class), any(Supplier.class))).thenAnswer(call -> {
            entered.add(call.getArgument(0));
            return ((Supplier<?>) call.getArgument(1)).get();
        });
    }

    @Test
    void aKnownEventIdChangesNothing() {
        RosterEvent event = event(new TenantChanged("ACTIVE", JAKARTA));
        when(store.markApplied(event)).thenReturn(false);

        assertThat(apply.apply(event)).isEqualTo(Outcome.DUPLICATE);
        verify(store, never()).tenant(any(), any());
        verifyNoInteractions(registry);
        assertThat(entered).containsExactly(TENANT);
    }

    @ParameterizedTest
    @ValueSource(booleans = {true, false})
    void everyChangeGoesToItsOwnWriteAndAnOlderOneIsStale(boolean written) {
        Outcome expected = written ? Outcome.APPLIED : Outcome.STALE;
        PersonChanged person = new PersonChanged("Ana", Optional.empty(), Set.of(), true);
        PlayerChanged player = new PlayerChanged(PERSON, "Ana", "ACTIVE", Optional.empty(), Optional.empty());
        TeamChanged team = new TeamChanged(UUID.randomUUID(), DAY, "U12");
        TeamPlayerChanged teamPlayer = new TeamPlayerChanged(TEAM, PLAYER, Optional.empty(), DAY, Optional.empty(),
                Optional.empty());
        TeamStaffChanged staff = new TeamStaffChanged(TEAM, PERSON, "COACH", DAY);
        TeamStaffRemoved staffRemoved = new TeamStaffRemoved(TEAM, PERSON);
        GuardianLinkChanged link = new GuardianLinkChanged(PERSON, PLAYER);
        GuardianLinkRemoved linkRemoved = new GuardianLinkRemoved(PERSON, PLAYER);
        RosterChange.Removed removed = new RosterChange.Removed(RosterTopic.PLAYER);
        when(store.markApplied(any())).thenReturn(true);
        when(store.person(any(), any())).thenReturn(written);
        when(store.player(any(), any())).thenReturn(written);
        when(store.team(any(), any())).thenReturn(written);
        when(store.teamPlayer(any(), any())).thenReturn(written);
        when(store.teamStaff(any(), any())).thenReturn(written);
        when(store.teamStaffRemoved(any(), any())).thenReturn(written);
        when(store.guardianLink(any(), any())).thenReturn(written);
        when(store.guardianLinkRemoved(any(), any())).thenReturn(written);
        when(store.removed(any(), any())).thenReturn(written);

        RosterEvent personEvent = event(person);
        assertThat(apply.apply(personEvent)).isEqualTo(expected);
        verify(store).person(personEvent, person);
        RosterEvent playerEvent = event(player);
        assertThat(apply.apply(playerEvent)).isEqualTo(expected);
        verify(store).player(playerEvent, player);
        RosterEvent teamEvent = event(team);
        assertThat(apply.apply(teamEvent)).isEqualTo(expected);
        verify(store).team(teamEvent, team);
        RosterEvent teamPlayerEvent = event(teamPlayer);
        assertThat(apply.apply(teamPlayerEvent)).isEqualTo(expected);
        verify(store).teamPlayer(teamPlayerEvent, teamPlayer);
        RosterEvent staffEvent = event(staff);
        assertThat(apply.apply(staffEvent)).isEqualTo(expected);
        verify(store).teamStaff(staffEvent, staff);
        RosterEvent staffRemovedEvent = event(staffRemoved);
        assertThat(apply.apply(staffRemovedEvent)).isEqualTo(expected);
        verify(store).teamStaffRemoved(staffRemovedEvent, staffRemoved);
        RosterEvent linkEvent = event(link);
        assertThat(apply.apply(linkEvent)).isEqualTo(expected);
        verify(store).guardianLink(linkEvent, link);
        RosterEvent linkRemovedEvent = event(linkRemoved);
        assertThat(apply.apply(linkRemovedEvent)).isEqualTo(expected);
        verify(store).guardianLinkRemoved(linkRemovedEvent, linkRemoved);
        RosterEvent removedEvent = event(removed);
        assertThat(apply.apply(removedEvent)).isEqualTo(expected);
        verify(store).removed(removedEvent, removed);
        verifyNoInteractions(registry);
    }

    @Test
    void aWrittenTenantEventRegistersTheTenantsZone() {
        TenantChanged change = new TenantChanged("ACTIVE", JAKARTA);
        RosterEvent event = event(change);
        when(store.markApplied(event)).thenReturn(true);
        when(store.tenant(event, change)).thenReturn(true);

        assertThat(apply.apply(event)).isEqualTo(Outcome.APPLIED);
        verify(registry).register(TENANT, JAKARTA);
    }

    @Test
    void aStaleTenantEventLeavesTheRegistryAlone() {
        TenantChanged change = new TenantChanged("ACTIVE", JAKARTA);
        RosterEvent event = event(change);
        when(store.markApplied(event)).thenReturn(true);
        when(store.tenant(event, change)).thenReturn(false);

        assertThat(apply.apply(event)).isEqualTo(Outcome.STALE);
        verifyNoInteractions(registry);
    }

    private static RosterEvent event(RosterChange change) {
        return new RosterEvent(UUID.randomUUID(), TENANT, UUID.randomUUID(), Instant.parse("2026-11-07T10:00:00Z"),
                change);
    }
}
