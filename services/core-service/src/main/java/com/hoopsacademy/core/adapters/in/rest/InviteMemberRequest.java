package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.application.members.InviteMemberCommand;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/** Contract {@code InviteMemberRequest} (PersonalData + roles + sendInvitation). */
public record InviteMemberRequest(
        @NotBlank @Size(max = 80) String givenName,
        @NotBlank @Size(max = 80) String familyName,
        @Email @Size(max = 254) String email,
        @Size(max = 32) String phone,
        LocalDate birthDate,
        @Pattern(regexp = Constraints.GENDER) String gender,
        @Pattern(regexp = Constraints.LOCALE) String locale,
        @NotNull @NotEmpty List<@NotNull @Pattern(regexp = Constraints.TENANT_ROLE) String> roles,
        Boolean sendInvitation) {

    InviteMemberCommand toCommand() {
        PersonalData data = new PersonalData(givenName, familyName, email, phone, birthDate,
                gender == null ? null : Gender.valueOf(gender), locale == null ? null : AppLocale.fromCode(locale));
        return new InviteMemberCommand(data, rolesOf(roles), sendInvitation == null || sendInvitation);
    }

    static Set<TenantRole> rolesOf(List<String> roles) {
        Set<TenantRole> result = EnumSet.noneOf(TenantRole.class);
        roles.forEach(role -> result.add(TenantRole.valueOf(role)));
        return result;
    }
}
