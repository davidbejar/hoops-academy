package com.hoopsacademy.core.domain.tenant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

class TenantProfileTest {

    private final TenantProfile profile = new TenantProfile(TenantId.random(), "acme", "Acme", ZoneId.of("UTC"),
            AppLocale.EN, "info@acme.test", "https://acme.test", TenantStatus.ACTIVE);

    @Test
    void appliesPresentChangesAndClearsNullableContactFields() {
        TenantProfile changed = profile.apply(new TenantProfileChanges(Patch.of("Acme 2"), Patch.of(ZoneId.of("Asia/Jakarta")),
                Patch.absent(), Patch.of(null), Patch.absent()));
        assertThat(changed.name()).isEqualTo("Acme 2");
        assertThat(changed.timezone()).isEqualTo(ZoneId.of("Asia/Jakarta"));
        assertThat(changed.defaultLocale()).isEqualTo(AppLocale.EN);
        assertThat(changed.contactEmail()).isNull();
        assertThat(changed.websiteUrl()).isEqualTo("https://acme.test");
    }

    @Test
    void requiredFieldsCannotBeCleared() {
        assertThatThrownBy(() -> profile.apply(new TenantProfileChanges(Patch.of(null), Patch.absent(),
                Patch.absent(), Patch.absent(), Patch.absent()))).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> profile.apply(new TenantProfileChanges(Patch.absent(), Patch.absent(),
                Patch.of(null), Patch.absent(), Patch.absent()))).isInstanceOf(DomainRuleViolation.class);
    }
}
