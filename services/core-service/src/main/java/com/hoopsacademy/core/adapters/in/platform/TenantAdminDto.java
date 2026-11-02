package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.application.members.MemberView;
import com.hoopsacademy.core.application.platform.ManageTenantAdmins;
import com.hoopsacademy.core.domain.membership.Person;
import java.util.List;
import java.util.UUID;

/** Contract {@code TenantAdmin}: identity of an administrator, nothing else of the tenant's content. */
public record TenantAdminDto(UUID personId, String givenName, String familyName, String email,
        String invitationStatus, List<String> otherRoles) {

    static TenantAdminDto of(MemberView view) {
        Person person = view.person();
        return new TenantAdminDto(person.id().value(), person.data().givenName(), person.data().familyName(),
                person.data().email(), person.invitationStatus().name(),
                ManageTenantAdmins.otherRoles(person).stream().map(Enum::name).sorted().toList());
    }
}
