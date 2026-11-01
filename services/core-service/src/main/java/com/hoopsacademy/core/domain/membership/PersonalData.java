package com.hoopsacademy.core.domain.membership;

import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Require;
import java.time.LocalDate;

/** Personal data of a member; names are required, everything else optional. */
public record PersonalData(
        String givenName,
        String familyName,
        String email,
        String phone,
        LocalDate birthDate,
        Gender gender,
        AppLocale locale) {

    private static final int MAX_NAME = 80;

    public PersonalData {
        givenName = Require.text(givenName, "givenName", MAX_NAME);
        familyName = Require.text(familyName, "familyName", MAX_NAME);
    }

    public String displayName() {
        return givenName + " " + familyName;
    }

    PersonalData apply(PersonalDataChanges changes) {
        if (changes.locale().clears()) {
            throw Require.violation("locale", "locale cannot be cleared");
        }
        return new PersonalData(changes.givenName().applyTo(givenName), changes.familyName().applyTo(familyName),
                changes.email().applyTo(email), changes.phone().applyTo(phone),
                changes.birthDate().applyTo(birthDate), changes.gender().applyTo(gender),
                changes.locale().applyTo(locale));
    }
}
