package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.application.signup.DecideAcademyRequest;

/** Contract {@code AcademyRequestAccepted} without {@code temporaryPassword} (added by {@code WithPasswordDto}). */
public record AcademyRequestAcceptedDto(AcademyRequestDto request, TenantDto tenant) {

    static AcademyRequestAcceptedDto of(DecideAcademyRequest.AcceptedAcademy accepted) {
        return new AcademyRequestAcceptedDto(AcademyRequestDto.of(accepted.request()), TenantDto.of(accepted.tenant()));
    }
}
