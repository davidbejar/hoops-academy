package com.hoopsacademy.core.application.signup;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.platform.CreateTenant;
import com.hoopsacademy.core.application.platform.CreateTenantCommand;
import com.hoopsacademy.core.application.port.AcademyRequestNotifier;
import com.hoopsacademy.core.application.port.AcademyRequestRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.signup.AcademyName;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import com.hoopsacademy.core.domain.signup.AcademyRequestId;
import com.hoopsacademy.core.domain.signup.AcademyRequestStatus;
import com.hoopsacademy.core.domain.signup.Requester;
import com.hoopsacademy.core.domain.signup.RequesterRole;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import java.time.Instant;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/** The decision saga's own rules, without Quarkus: the e-mail never undoes a decision, a failure reopens the claim. */
class DecideAcademyRequestTest {

    private static final Instant NOW = Instant.parse("2026-11-07T12:00:00Z");
    private static final AcademyRequestId ID = AcademyRequestId.random();
    private static final AcademyRequest PENDING = AcademyRequest.submit(ID,
            Requester.of("Ana", "ana@example.com", RequesterRole.PARENT, AppLocale.ID), AcademyName.of("Club"), NOW);
    private static final DecideAcademyRequest.Acceptance ACCEPTANCE = new DecideAcademyRequest.Acceptance(
            TenantSlug.of("club"), ZoneId.of("Asia/Jakarta"), AppLocale.EN, "Ana", "Ruiz", null);

    private final AcademyRequestRepository requests = mock(AcademyRequestRepository.class);
    private final AcademyRequestSteps steps = mock(AcademyRequestSteps.class);
    private final CreateTenant createTenant = mock(CreateTenant.class);
    private final AcademyRequestNotifier notifier = mock(AcademyRequestNotifier.class);
    private final DecideAcademyRequest decide = new DecideAcademyRequest(requests, steps, createTenant, notifier);

    @Test
    void theInboxListsWhatTheRepositoryHolds() {
        PageRequest page = new PageRequest(0, 20);
        PageResult<AcademyRequest> held = new PageResult<>(java.util.List.of(PENDING), page, 1);
        when(requests.list(java.util.Optional.of(AcademyRequestStatus.PENDING), page)).thenReturn(held);

        assertThat(decide.list(java.util.Optional.of(AcademyRequestStatus.PENDING), page)).isSameAs(held);
    }

    @Test
    void aRejectionStandsWhenItsEmailCannotBeSent() {
        AcademyRequest rejected = PENDING.reject("no", "sub", NOW);
        when(steps.reject(ID, "no", "sub")).thenReturn(rejected);
        when(notifier.rejected(rejected)).thenReturn(false);

        assertThat(decide.reject(ID, "no", "sub")).isSameAs(rejected);
        verify(steps, never()).notified(any());
    }

    @Test
    void aSentEmailIsRecorded() {
        AcademyRequest rejected = PENDING.reject("no", "sub", NOW);
        AcademyRequest notified = rejected.notified(NOW);
        when(steps.reject(ID, "no", "sub")).thenReturn(rejected);
        when(notifier.rejected(rejected)).thenReturn(true);
        when(steps.notified(rejected)).thenReturn(notified);

        assertThat(decide.reject(ID, "no", "sub")).isSameAs(notified);
    }

    @Test
    void anAcceptanceOnboardsWithTheRequestersEmailAndLanguageAndTellsTheMailWhetherTheLoginIsNew() {
        ArgumentCaptor<TenantId> tenantId = ArgumentCaptor.forClass(TenantId.class);
        when(steps.claim(eq(ID), tenantId.capture(), eq("sub")))
                .thenAnswer(call -> PENDING.accept(call.getArgument(1), "sub", NOW));
        ArgumentCaptor<CreateTenantCommand> command = ArgumentCaptor.forClass(CreateTenantCommand.class);
        Tenant tenant = Tenant.onboard(TenantId.random(), TenantSlug.of("club"), "Club", ZoneId.of("Asia/Jakarta"),
                AppLocale.EN, NOW);
        when(createTenant.handle(any(TenantId.class), command.capture()))
                .thenReturn(WithTemporaryPassword.without(tenant));
        when(notifier.accepted(any(), anyBoolean())).thenReturn(false);

        WithTemporaryPassword<DecideAcademyRequest.AcceptedAcademy> result = decide.accept(ID, ACCEPTANCE, "sub");

        verify(createTenant).handle(eq(tenantId.getValue()), any());
        assertThat(command.getValue().name()).isEqualTo("Club");
        assertThat(command.getValue().firstAdmin().email()).isEqualTo("ana@example.com");
        assertThat(command.getValue().firstAdmin().locale()).as("the request's language").isEqualTo(AppLocale.ID);
        assertThat(command.getValue().firstAdmin().givenName()).isEqualTo("Ana");
        assertThat(command.getValue().defaultLocale()).isEqualTo(AppLocale.EN);
        verify(steps).recordAcceptance(result.value().request());
        verify(notifier).accepted(result.value().request(), false);
        assertThat(result.value().tenant()).isSameAs(tenant);
        assertThat(result.temporaryPassword()).isEmpty();
    }

    @Test
    void theAdministratorsChosenLanguageWinsOverTheRequests() {
        when(steps.claim(eq(ID), any(), eq("sub"))).thenAnswer(call -> PENDING.accept(call.getArgument(1), "sub", NOW));
        ArgumentCaptor<CreateTenantCommand> command = ArgumentCaptor.forClass(CreateTenantCommand.class);
        when(createTenant.handle(any(TenantId.class), command.capture())).thenReturn(WithTemporaryPassword.without(
                Tenant.onboard(TenantId.random(), TenantSlug.of("club"), "Club", ZoneId.of("UTC"), AppLocale.EN, NOW)));

        decide.accept(ID, new DecideAcademyRequest.Acceptance(TenantSlug.of("club"), ZoneId.of("UTC"), AppLocale.EN,
                "Ana", "Ruiz", AppLocale.ES), "sub");

        assertThat(command.getValue().firstAdmin().locale()).isEqualTo(AppLocale.ES);
    }

    @Test
    void aFailedOnboardingReopensTheClaimAndKeepsItsOwnError() {
        when(steps.claim(eq(ID), any(), eq("sub"))).thenAnswer(call -> PENDING.accept(call.getArgument(1), "sub", NOW));
        ConflictException slugTaken = new ConflictException("taken", "SLUG_TAKEN");
        when(createTenant.handle(any(TenantId.class), any())).thenThrow(slugTaken);
        IllegalStateException releaseFailed = new IllegalStateException("db down");
        doThrow(releaseFailed).when(steps).release(eq(ID), any());

        assertThatThrownBy(() -> decide.accept(ID, ACCEPTANCE, "sub")).isSameAs(slugTaken)
                .satisfies(e -> assertThat(e.getSuppressed()).containsExactly(releaseFailed));
        verify(steps, never()).recordAcceptance(any());
        verify(notifier, never()).accepted(any(), anyBoolean());
    }
}
