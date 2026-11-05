package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.members.MemberView;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Contract {@code Member}. */
public record MemberDto(UUID personId, UUID userId, String givenName, String familyName, String displayName,
        String email, String phone, LocalDate birthDate, String gender, String locale, List<String> roles,
        UUID playerId, boolean active, String invitationStatus, String temporaryPasswordStatus, Instant createdAt) {

    static MemberDto of(MemberView view) {
        Person person = view.person();
        PersonalData data = person.data();
        return new MemberDto(person.id().value(), person.userId() == null ? null : person.userId().value(),
                data.givenName(), data.familyName(), data.displayName(), data.email(), data.phone(), data.birthDate(),
                data.gender() == null ? null : data.gender().name(),
                data.locale() == null ? null : data.locale().code(),
                person.roles().stream().map(Enum::name).sorted().toList(),
                view.playerId().map(PlayerId::value).orElse(null), person.active(), person.invitationStatus().name(),
                view.temporaryPassword().name(), person.createdAt());
    }
}
