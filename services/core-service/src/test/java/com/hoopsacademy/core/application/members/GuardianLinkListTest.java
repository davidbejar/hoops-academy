package com.hoopsacademy.core.application.members;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.GuardianLink;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/** CORE-01 (audit 2026-11-23): the guardian-link list resolves its names with a fixed number of reads per page. */
class GuardianLinkListTest {

    private static final Instant NOW = Instant.parse("2026-11-23T10:00:00Z");
    private static final PageRequest PAGE = new PageRequest(0, 50);

    private final GuardianLinkRepository links = mock(GuardianLinkRepository.class);
    private final PersonRepository persons = mock(PersonRepository.class);
    private final PlayerRepository players = mock(PlayerRepository.class);
    private final GuardianLinkService service = new GuardianLinkService(mock(TenantContext.class), links, persons,
            players, mock(AuthzCache.class), mock(AuditLog.class), mock(MemberProvisioning.class),
            mock(TemporaryPasswords.class), Clock.systemUTC());

    @Test
    void namesEveryLinkOfAPageWithOnePlayerReadAndOnePersonReadForTheGuardians() {
        Person mother = parent("Ana", "Ruiz");
        Person father = parent("Luis", "Ruiz");
        PlayerSummary kid = player("Leo", "Ruiz");
        PlayerSummary sister = player("Eva", "Ruiz");
        List<GuardianLink> page = List.of(link(mother, kid), link(father, kid), link(mother, sister));
        when(links.list(Optional.empty(), Optional.empty(), PAGE)).thenReturn(new PageResult<>(page, PAGE, 3));
        when(players.summaries(anyCollection())).thenReturn(Map.of(kid.id(), kid, sister.id(), sister));
        when(persons.findAll(anyCollection())).thenReturn(List.of(mother, father));

        PageResult<GuardianLinkService.LinkView> views = service.list(Optional.empty(), Optional.empty(), PAGE);

        assertThat(views.items()).extracting(GuardianLinkService.LinkView::guardianName,
                        GuardianLinkService.LinkView::playerName)
                .containsExactly(org.assertj.core.groups.Tuple.tuple("Ana Ruiz", "Leo Ruiz"),
                        org.assertj.core.groups.Tuple.tuple("Luis Ruiz", "Leo Ruiz"),
                        org.assertj.core.groups.Tuple.tuple("Ana Ruiz", "Eva Ruiz"));
        assertThat(views.totalElements()).isEqualTo(3);
        verify(players, never()).personOf(any());
        verify(players, times(1)).summaries(anyCollection());
        @SuppressWarnings("unchecked")
        ArgumentCaptor<Collection<PersonId>> asked = ArgumentCaptor.forClass(Collection.class);
        verify(persons, times(1)).findAll(asked.capture());
        assertThat(asked.getValue()).as("the guardians only: the players' names come with their summaries")
                .containsExactlyInAnyOrder(mother.id(), father.id());
    }

    @Test
    void aLinkWhosePlayerIsGoneKeepsAnEmptyPlayerName() {
        Person mother = parent("Ana", "Ruiz");
        PlayerSummary gone = player("Leo", "Ruiz");
        when(links.list(Optional.empty(), Optional.empty(), PAGE))
                .thenReturn(new PageResult<>(List.of(link(mother, gone)), PAGE, 1));
        when(players.summaries(anyCollection())).thenReturn(Map.of());
        when(persons.findAll(anyCollection())).thenReturn(List.of(mother));

        assertThat(service.list(Optional.empty(), Optional.empty(), PAGE).items())
                .extracting(GuardianLinkService.LinkView::playerName).containsExactly("");
    }

    private static Person parent(String given, String family) {
        return Person.create(PersonId.random(), new PersonalData(given, family, null, null, null, null, null),
                Set.of(TenantRole.PARENT), NOW);
    }

    private static PlayerSummary player(String given, String family) {
        return new PlayerSummary(PlayerId.random(), PersonId.random(), given + " " + family, PlayerStatus.ACTIVE,
                LocalDate.of(2014, 3, 1), Gender.FEMALE, given, family, null);
    }

    private static GuardianLink link(Person guardian, PlayerSummary player) {
        return new GuardianLink(GuardianLinkId.random(), guardian.id(), player.id(), NOW);
    }
}
