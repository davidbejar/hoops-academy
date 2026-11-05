package com.hoopsacademy.core.domain.membership;

import static com.hoopsacademy.common.tenancy.TenantRole.ADMIN;
import static com.hoopsacademy.common.tenancy.TenantRole.COACH;
import static com.hoopsacademy.common.tenancy.TenantRole.PARENT;
import static com.hoopsacademy.common.tenancy.TenantRole.PLAYER;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Set;
import org.junit.jupiter.api.Test;

class PersonTest {

    private static final Instant NOW = Instant.parse("2026-11-01T10:00:00Z");
    private static final PersonalData ADULT = new PersonalData("Ana", "García", "ana@acme.test", null, null, null,
            AppLocale.ES);
    private static final PersonalData KID = new PersonalData("Leo", "Pérez", null, null, LocalDate.of(2014, 3, 1),
            Gender.MALE, null);

    @Test
    void inviteCreatesAnActivePersonWithoutLogin() {
        Person person = Person.create(PersonId.random(), ADULT, Set.of(COACH, PARENT), NOW);
        assertThat(person.active()).isTrue();
        assertThat(person.roles()).containsExactlyInAnyOrder(COACH, PARENT);
        assertThat(person.invitationStatus()).isEqualTo(InvitationStatus.NONE);
        assertThat(person.userId()).isNull();
        assertThat(person.displayName()).isEqualTo("Ana García");
    }

    @Test
    void playerRoleRequiresBirthDateAndGender() {
        assertThatThrownBy(() -> Person.create(PersonId.random(), ADULT, Set.of(PLAYER), NOW))
                .isInstanceOfSatisfying(DomainRuleViolation.class, e -> {
                    assertThat(e.code()).isEqualTo("PLAYER_REQUIRES_BIRTH_AND_GENDER");
                    assertThat(e.reasons()).extracting(v -> v.field()).containsExactlyInAnyOrder("birthDate", "gender");
                });
        assertThat(Person.create(PersonId.random(), KID, Set.of(PLAYER), NOW).isPlayer()).isTrue();
    }

    @Test
    void atLeastOneRole() {
        assertThatThrownBy(() -> Person.create(PersonId.random(), ADULT, Set.of(), NOW))
                .isInstanceOfSatisfying(DomainRuleViolation.class, e -> assertThat(e.code()).isEqualTo("ROLES_REQUIRED"));
        assertThatThrownBy(() -> Person.create(PersonId.random(), ADULT, null, NOW))
                .isInstanceOfSatisfying(DomainRuleViolation.class, e -> assertThat(e.code()).isEqualTo("ROLES_REQUIRED"));
    }

    @Test
    void rolesAnswerWhetherThePersonIsAdminOrPlayer() {
        Person admin = Person.create(PersonId.random(), ADULT, Set.of(ADMIN), NOW);
        Person player = Person.create(PersonId.random(), KID, Set.of(PLAYER), NOW);

        assertThat(admin.isAdmin()).isTrue();
        assertThat(admin.isPlayer()).isFalse();
        assertThat(player.isAdmin()).isFalse();
        assertThat(player.isPlayer()).isTrue();
    }

    @Test
    void replacingRolesRevalidatesPlayerData() {
        Person coach = Person.create(PersonId.random(), ADULT, Set.of(COACH), NOW);
        assertThatThrownBy(() -> coach.withRoles(Set.of(COACH, PLAYER))).isInstanceOf(DomainRuleViolation.class);
        assertThat(coach.withRoles(Set.of(ADMIN)).roles()).containsExactly(ADMIN);
    }

    @Test
    void changingDataKeepsPlayerInvariant() {
        Person kid = Person.create(PersonId.random(), KID, Set.of(PLAYER), NOW);
        assertThatThrownBy(() -> kid.withData(PersonalDataChanges.none().withBirthDate(Patch.of(null))))
                .isInstanceOf(DomainRuleViolation.class);
        Person renamed = kid.withData(PersonalDataChanges.none().withGivenName(Patch.of("Leon"))
                .withPhone(Patch.of("+34 600")));
        assertThat(renamed.data().givenName()).isEqualTo("Leon");
        assertThat(renamed.data().phone()).isEqualTo("+34 600");
        assertThat(renamed.data().birthDate()).isEqualTo(KID.birthDate());
    }

    @Test
    void namesCannotBeCleared() {
        Person person = Person.create(PersonId.random(), ADULT, Set.of(COACH), NOW);
        assertThatThrownBy(() -> person.withData(PersonalDataChanges.none().withFamilyName(Patch.of(" "))))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> person.withData(PersonalDataChanges.none().withLocale(Patch.of(null))))
                .isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void allPersonalFieldsCanBePatched() {
        Person person = Person.create(PersonId.random(), ADULT, Set.of(COACH), NOW);
        Person changed = person.withData(PersonalDataChanges.none()
                .withEmail(Patch.of(null)).withGender(Patch.of(Gender.FEMALE))
                .withBirthDate(Patch.of(LocalDate.of(1990, 1, 1))).withLocale(Patch.of(AppLocale.EN)));
        assertThat(changed.data()).isEqualTo(new PersonalData("Ana", "García", null, null, LocalDate.of(1990, 1, 1),
                Gender.FEMALE, AppLocale.EN));
    }

    @Test
    void loginLinkAndDeactivation() {
        Person person = Person.create(PersonId.random(), ADULT, Set.of(COACH), NOW);
        UserId user = UserId.random();
        Person invited = person.linkLogin(user, InvitationStatus.PENDING);
        assertThat(invited.userId()).isEqualTo(user);
        assertThat(invited.invitationStatus()).isEqualTo(InvitationStatus.PENDING);
        assertThat(invited.acceptInvitation().invitationStatus()).isEqualTo(InvitationStatus.ACCEPTED);
        Person inactive = invited.deactivate(NOW);
        assertThat(inactive.active()).isFalse();
        assertThat(inactive.deactivatedAt()).isEqualTo(NOW);
    }
}
