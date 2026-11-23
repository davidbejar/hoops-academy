package com.hoopsacademy.core.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Locale;
import org.junit.jupiter.api.Test;

/** CORE-09: one LIKE pattern for the "contains" searches of the lists (escape character {@code \}). */
class LikePatternTest {

    @Test
    void aSearchTextIsLowerCasedAndWrappedInWildcards() {
        assertThat(LikePattern.contains("Ana Ruiz")).isEqualTo("%ana ruiz%");
    }

    @Test
    void theWildcardsAndTheEscapeCharacterOfTheTextMatchThemselves() {
        assertThat(LikePattern.contains("50%_a\\b")).isEqualTo("%50\\%\\_a\\\\b%");
    }

    @Test
    void lowerCasingDoesNotDependOnTheDefaultLocale() {
        Locale before = Locale.getDefault();
        Locale.setDefault(Locale.forLanguageTag("tr"));
        try {
            assertThat(LikePattern.contains("ILKER")).isEqualTo("%ilker%");
        } finally {
            Locale.setDefault(before);
        }
    }
}
