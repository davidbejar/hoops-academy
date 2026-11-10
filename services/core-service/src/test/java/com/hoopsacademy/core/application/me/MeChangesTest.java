package com.hoopsacademy.core.application.me;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import com.hoopsacademy.core.domain.shared.Patch;
import org.junit.jupiter.api.Test;

/** WP91: an own-name change carries only names (never the e-mail) and at least one of them. */
class MeChangesTest {

    private static final TenantId ACADEMY = TenantId.random();

    @Test
    void anOwnNameChangesTheNamesAndNothingElse() {
        PersonalDataChanges changes = new MeChanges.OwnName(ACADEMY, Patch.of("Ada"), Patch.absent()).changes();

        assertThat(changes.givenName().applyTo("Old")).isEqualTo("Ada");
        assertThat(changes.familyName().isPresent()).isFalse();
        assertThat(changes.email().isPresent()).isFalse();
        assertThat(changes.phone().isPresent()).isFalse();
        assertThat(changes.birthDate().isPresent()).isFalse();
        assertThat(changes.gender().isPresent()).isFalse();
        assertThat(changes.locale().isPresent()).isFalse();
    }

    @Test
    void anOwnNameNeedsAnAcademyAndAName() {
        assertThatThrownBy(() -> new MeChanges.OwnName(ACADEMY, Patch.absent(), Patch.absent()))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new MeChanges.OwnName(null, Patch.of("Ada"), Patch.absent()))
                .isInstanceOf(NullPointerException.class);
        assertThat(new MeChanges.OwnName(ACADEMY, Patch.absent(), Patch.of("Byron")).familyName().applyTo(null))
                .isEqualTo("Byron");
    }
}
