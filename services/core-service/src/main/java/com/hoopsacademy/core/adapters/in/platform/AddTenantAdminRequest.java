package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Contract {@code AddTenantAdminRequest}. */
public record AddTenantAdminRequest(
        @NotBlank @Email @Size(max = 254) String email,
        @NotBlank @Size(max = 80) String givenName,
        @NotBlank @Size(max = 80) String familyName,
        @Pattern(regexp = Constraints.LOCALE) String locale) {

    PersonalData toPersonalData() {
        return new PersonalData(givenName, familyName, email, null, null, null,
                locale == null ? null : AppLocale.fromCode(locale));
    }
}
