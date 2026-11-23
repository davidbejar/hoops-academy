package com.hoopsacademy.core.application.me;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.authz.MemberAuthz;
import com.hoopsacademy.core.application.authz.MembershipLookup;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.LogoRepository;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.TemporaryPasswordLogins;
import com.hoopsacademy.core.application.port.TemporaryPasswordSweeps;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/**
 * CORE-14 (audit 2026-11-23): /me builds each academy's membership from what the membership lookup already loaded
 * (the person and the tenant profile) instead of reading them a second time.
 */
class MeLookupTest {

    private static final String SUBJECT = "kc-sub-1";
    private static final TenantId TENANT = TenantId.random();
    private static final TenantProfile PROFILE = new TenantProfile(TENANT, "club", "Club", ZoneId.of("Europe/Madrid"),
            AppLocale.ES, null, null, TenantStatus.ACTIVE);
    private static final Person PERSON = Person.create(PersonId.random(),
            new PersonalData("Ana", "Ruiz", null, null, null, null, null), Set.of(TenantRole.COACH),
            Instant.parse("2026-11-01T00:00:00Z"));

    private final MembershipLookup membershipLookup = mock(MembershipLookup.class);
    private final TenantProfileRepository profiles = mock(TenantProfileRepository.class);
    private final LogoRepository logos = mock(LogoRepository.class);
    private final PersonRepository persons = mock(PersonRepository.class);
    private final AuditLog audit = mock(AuditLog.class);
    private final MeLookup lookup = new MeLookup(mock(AppUserRepository.class), mock(MembershipRepository.class),
            membershipLookup, profiles, logos, persons, mock(TemporaryPasswordLogins.class),
            mock(TemporaryPasswordSweeps.class), audit);

    @Test
    void theMembershipOfAnAcademyIsBuiltWithoutReadingThePersonOrTheProfileAgain() {
        when(membershipLookup.findWithPerson(SUBJECT)).thenReturn(Optional.of(found(TenantStatus.ACTIVE)));
        when(logos.findEtag()).thenReturn(Optional.of("etag"));

        MeView.Membership membership = lookup.membershipInBoundTenant(SUBJECT).orElseThrow();

        assertThat(membership.name()).isEqualTo(new MeView.OwnName("Ana", "Ruiz"));
        assertThat(membership.tenant()).isEqualTo(new MeView.TenantSummary(TENANT, "club", "Club",
                TenantStatus.ACTIVE, AppLocale.ES, true));
        verify(persons, never()).findActiveByLogin(anyString());
        verify(profiles, never()).findCurrent();
    }

    @Test
    void anAcademyThatIsNotActiveGivesNoMembership() {
        when(membershipLookup.findWithPerson(SUBJECT)).thenReturn(Optional.of(found(TenantStatus.SUSPENDED)));

        assertThat(lookup.membershipInBoundTenant(SUBJECT)).isEmpty();
    }

    @Test
    void theOwnNameIsChangedOnThePersonTheLookupLoaded() {
        when(membershipLookup.findWithPerson(SUBJECT)).thenReturn(Optional.of(found(TenantStatus.ACTIVE)));

        lookup.renameOwnPerson(SUBJECT, PersonalDataChanges.none().withGivenName(Patch.of("Anabel")));

        ArgumentCaptor<Person> changed = ArgumentCaptor.forClass(Person.class);
        verify(persons).update(changed.capture());
        assertThat(changed.getValue().data().givenName()).isEqualTo("Anabel");
        verify(persons, never()).findActiveByLogin(anyString());
        verify(audit).recordAs(any(), any());
    }

    private static MembershipLookup.Found found(TenantStatus status) {
        AuthzContext context = new AuthzContext(SUBJECT, PERSON.id().value(), TENANT, PERSON.roles(), Set.of(),
                Set.of(), Optional.empty());
        TenantProfile profile = new TenantProfile(TENANT, PROFILE.slug(), PROFILE.name(), PROFILE.timezone(),
                PROFILE.defaultLocale(), null, null, status);
        return new MembershipLookup.Found(new MemberAuthz(context, status), PERSON, profile);
    }
}
