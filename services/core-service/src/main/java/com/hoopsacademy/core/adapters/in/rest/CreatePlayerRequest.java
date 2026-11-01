package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.application.approvals.CreatePlayer.Command;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/** Contract {@code CreatePlayerRequest}. */
public record CreatePlayerRequest(
        @NotBlank @Size(max = 80) String givenName,
        @NotBlank @Size(max = 80) String familyName,
        @NotNull LocalDate birthDate,
        @NotNull @Pattern(regexp = Constraints.GENDER) String gender,
        @Email @Size(max = 254) String email,
        UUID teamId,
        @Pattern(regexp = Constraints.JERSEY) String jerseyNumber,
        @Size(max = 500) String note) {

    Command toCommand() {
        PersonalData data = new PersonalData(givenName, familyName, email, null, birthDate, Gender.valueOf(gender), null);
        return new Command(data, Optional.ofNullable(teamId).map(TeamId::new),
                Optional.ofNullable(JerseyNumber.ofNullable(jerseyNumber)), note);
    }
}
