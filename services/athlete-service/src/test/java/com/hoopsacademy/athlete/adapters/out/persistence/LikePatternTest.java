package com.hoopsacademy.athlete.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Locale;
import org.junit.jupiter.api.Test;

class LikePatternTest {

    @Test
    void wrapsTheLowerCasedTermInWildcards() {
        assertThat(LikePattern.contains("Warm Up")).isEqualTo("%warm up%");
    }

    @Test
    void escapesTheLikeWildcardsAndTheEscapeCharacter() {
        assertThat(LikePattern.contains("50%_a\\b")).isEqualTo("%50\\%\\_a\\\\b%");
    }

    @Test
    void lowerCasesInTheRootLocaleWhateverTheDefault() {
        Locale before = Locale.getDefault();
        Locale.setDefault(Locale.forLanguageTag("tr"));
        try {
            assertThat(LikePattern.contains("INSIDE")).isEqualTo("%inside%");
        } finally {
            Locale.setDefault(before);
        }
    }
}
