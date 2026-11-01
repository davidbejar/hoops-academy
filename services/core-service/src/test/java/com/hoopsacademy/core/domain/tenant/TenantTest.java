package com.hoopsacademy.core.domain.tenant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

class TenantTest {

    private static final Instant NOW = Instant.parse("2026-11-01T10:15:30Z");

    private final Tenant active = Tenant.onboard(TenantId.random(), TenantSlug.of("acme-hoops"), "Acme Hoops",
            ZoneId.of("Europe/Madrid"), AppLocale.ES, NOW);

    @Test
    void onboardedTenantIsActive() {
        assertThat(active.status()).isEqualTo(TenantStatus.ACTIVE);
        assertThat(active.isActive()).isTrue();
        assertThat(active.createdAt()).isEqualTo(NOW);
        assertThat(active.suspendedAt()).isNull();
    }

    @Test
    void nameIsRequiredAndBounded() {
        assertThatThrownBy(() -> Tenant.onboard(TenantId.random(), TenantSlug.of("abc"), " ", ZoneId.of("UTC"),
                AppLocale.EN, NOW)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> Tenant.onboard(TenantId.random(), TenantSlug.of("abc"), "x".repeat(121),
                ZoneId.of("UTC"), AppLocale.EN, NOW)).isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void suspendThenReactivate() {
        Tenant suspended = active.suspend("unpaid", NOW);
        assertThat(suspended.status()).isEqualTo(TenantStatus.SUSPENDED);
        assertThat(suspended.suspendedAt()).isEqualTo(NOW);
        assertThat(suspended.statusReason()).isEqualTo("unpaid");
        assertThat(suspended.isActive()).isFalse();

        Tenant reactivated = suspended.reactivate();
        assertThat(reactivated.status()).isEqualTo(TenantStatus.ACTIVE);
        assertThat(reactivated.suspendedAt()).isNull();
        assertThat(reactivated.statusReason()).isNull();
    }

    @Test
    void onlyActiveTenantsCanBeSuspendedAndOnlySuspendedReactivated() {
        assertThatThrownBy(() -> active.reactivate()).isInstanceOf(ConflictException.class)
                .extracting(e -> ((ConflictException) e).code()).isEqualTo("TENANT_NOT_SUSPENDED");
        Tenant suspended = active.suspend("x", NOW);
        assertThatThrownBy(() -> suspended.suspend("again", NOW)).isInstanceOf(ConflictException.class)
                .extracting(e -> ((ConflictException) e).code()).isEqualTo("TENANT_NOT_ACTIVE");
    }

    @Test
    void withdrawIsTerminalAndSetsRetention() {
        Tenant withdrawn = active.suspend("x", NOW).withdraw("closed", NOW, Period.ofDays(365));
        assertThat(withdrawn.status()).isEqualTo(TenantStatus.WITHDRAWN);
        assertThat(withdrawn.withdrawnAt()).isEqualTo(NOW);
        assertThat(withdrawn.retainUntil()).isEqualTo(LocalDate.of(2027, 11, 1));
        assertThatThrownBy(() -> withdrawn.withdraw("again", NOW, Period.ofDays(1)))
                .isInstanceOf(ConflictException.class);
        assertThatThrownBy(withdrawn::reactivate).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> withdrawn.suspend("x", NOW)).isInstanceOf(ConflictException.class);
    }

    @Test
    void masterDataChangesOnlyTouchPresentFields() {
        Tenant renamed = active.changeMasterData(Patch.of("New Name"), Patch.absent(), Patch.of(AppLocale.ID));
        assertThat(renamed.name()).isEqualTo("New Name");
        assertThat(renamed.timezone()).isEqualTo(ZoneId.of("Europe/Madrid"));
        assertThat(renamed.defaultLocale()).isEqualTo(AppLocale.ID);
        assertThatThrownBy(() -> active.changeMasterData(Patch.of(""), Patch.absent(), Patch.absent()))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> active.changeMasterData(Patch.absent(), Patch.of(null), Patch.absent()))
                .isInstanceOf(DomainRuleViolation.class);
    }
}
