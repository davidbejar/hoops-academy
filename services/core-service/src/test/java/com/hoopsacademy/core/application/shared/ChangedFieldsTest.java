package com.hoopsacademy.core.application.shared;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.shared.AppLocale;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class ChangedFieldsTest {

    private static final PersonalData ANA = new PersonalData("Ana", "Ruiz", "ana@example.com", "1",
            LocalDate.of(2010, 1, 1), Gender.FEMALE, AppLocale.ES);

    @Test
    void onlyFieldsWhoseValueDiffersCount() {
        ChangedFields fields = new ChangedFields().field("name", "A", "A").field("zone", null, null)
                .field("phone", "1", null).field("alias", null, "x").field("email", "a", "b");

        assertThat(fields.isEmpty()).isFalse();
        assertThat(fields.names()).containsExactly("alias", "email", "phone");
    }

    @Test
    void repeatingTheStoredValuesChangesNothing() {
        ChangedFields fields = new ChangedFields().field("name", "A", "A").field("zone", null, null);

        assertThat(fields.isEmpty()).isTrue();
        assertThat(fields.names()).isEmpty();
    }

    @Test
    void personalDataIsComparedFieldByField() {
        assertThat(ChangedFields.of(ANA, ANA).isEmpty()).isTrue();
        PersonalData changed = new PersonalData("Anna", "Ruiz", null, "2", LocalDate.of(2010, 1, 2), Gender.MALE,
                AppLocale.EN);
        assertThat(ChangedFields.of(ANA, changed).names())
                .containsExactly("birthDate", "email", "gender", "givenName", "locale", "phone");
        PersonalData renamed = new PersonalData("Ana", "Ruiz-Gil", "ana@example.com", "1", LocalDate.of(2010, 1, 1),
                Gender.FEMALE, AppLocale.ES);
        assertThat(ChangedFields.of(ANA, renamed).names()).containsExactly("familyName");
    }
}
