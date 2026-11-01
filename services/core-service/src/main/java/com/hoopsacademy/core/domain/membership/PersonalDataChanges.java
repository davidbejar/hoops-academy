package com.hoopsacademy.core.domain.membership;

import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.LocalDate;

/** A partial update of {@link PersonalData}. */
public record PersonalDataChanges(
        Patch<String> givenName,
        Patch<String> familyName,
        Patch<String> email,
        Patch<String> phone,
        Patch<LocalDate> birthDate,
        Patch<Gender> gender,
        Patch<AppLocale> locale) {

    public static PersonalDataChanges none() {
        return new PersonalDataChanges(Patch.absent(), Patch.absent(), Patch.absent(), Patch.absent(),
                Patch.absent(), Patch.absent(), Patch.absent());
    }

    public PersonalDataChanges withGivenName(Patch<String> value) {
        return new PersonalDataChanges(value, familyName, email, phone, birthDate, gender, locale);
    }

    public PersonalDataChanges withFamilyName(Patch<String> value) {
        return new PersonalDataChanges(givenName, value, email, phone, birthDate, gender, locale);
    }

    public PersonalDataChanges withEmail(Patch<String> value) {
        return new PersonalDataChanges(givenName, familyName, value, phone, birthDate, gender, locale);
    }

    public PersonalDataChanges withPhone(Patch<String> value) {
        return new PersonalDataChanges(givenName, familyName, email, value, birthDate, gender, locale);
    }

    public PersonalDataChanges withBirthDate(Patch<LocalDate> value) {
        return new PersonalDataChanges(givenName, familyName, email, phone, value, gender, locale);
    }

    public PersonalDataChanges withGender(Patch<Gender> value) {
        return new PersonalDataChanges(givenName, familyName, email, phone, birthDate, value, locale);
    }

    public PersonalDataChanges withLocale(Patch<AppLocale> value) {
        return new PersonalDataChanges(givenName, familyName, email, phone, birthDate, gender, value);
    }
}
