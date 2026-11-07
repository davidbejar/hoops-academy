package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.Constraints;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Contract {@code AcceptAcademyRequest}. */
public record AcceptAcademyRequestBody(
        @NotNull @Pattern(regexp = Constraints.SLUG) String slug,
        @NotBlank @Size(max = 64) String timezone,
        @NotNull @Pattern(regexp = Constraints.LOCALE) String defaultLocale,
        @NotNull @Valid Admin firstAdmin) {

    /** Contract {@code AcceptedAdmin}. */
    public record Admin(
            @NotBlank @Size(max = 80) String givenName,
            @NotBlank @Size(max = 80) String familyName,
            @Pattern(regexp = Constraints.LOCALE) String locale) {}
}
