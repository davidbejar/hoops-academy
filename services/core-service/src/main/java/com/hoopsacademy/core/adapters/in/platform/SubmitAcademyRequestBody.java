package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.Constraints;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Contract {@code SubmitAcademyRequest}: bounded, single-line text from an anonymous form (400 otherwise). */
public record SubmitAcademyRequestBody(
        @Size(max = 120) @Pattern(regexp = SubmitAcademyRequestBody.ONE_LINE) String name,
        @NotBlank @Email @Size(max = 254) @Pattern(regexp = SubmitAcademyRequestBody.NO_SPACE) String email,
        @NotNull @Pattern(regexp = SubmitAcademyRequestBody.ROLE) String role,
        @NotBlank @Size(max = 120) @Pattern(regexp = SubmitAcademyRequestBody.ONE_LINE) String academyName,
        @Pattern(regexp = Constraints.LOCALE) String locale,
        @Size(max = 2048) String website) {

    static final String ROLE = "ADMIN|COACH|PARENT";
    /** No control or format characters (line breaks, NUL, bidi overrides). */
    static final String ONE_LINE = "^[^\\p{Cc}\\p{Cf}]*$";
    static final String NO_SPACE = "^[^\\s\\p{Cc}\\p{Cf}]*$";

    boolean honeypotFilled() {
        return website != null && !website.isEmpty();
    }
}
