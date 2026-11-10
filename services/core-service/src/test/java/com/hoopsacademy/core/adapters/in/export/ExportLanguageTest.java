package com.hoopsacademy.core.adapters.in.export;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.shared.AppLocale;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** ADR-0048: the labels of a server export follow {@code Accept-Language}, as the athlete templates do. */
class ExportLanguageTest {

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "es|ES",
            "en|EN",
            "id|ID",
            "in|ID",
            "es-AR|ES",
            "ID-id|ID",
            "fr, id;q=0.5, es;q=0.4|ID",
            "en;q=0.2, es;q=0.9|ES",
            "es;q=0, id|ID",
            "es;q=1.0, en;q=1.0|ES",
            "en;q=1, es|EN",
            "fr, de|EN",
            "*|EN",
            "''|EN",
            ";q=1, es|ES",
            "es;q=abc, id;q=0.5|ES",
            "es; Q=0.1, id;q=0.5|ID",
            "es;level=1;q=0.1, id|ID"})
    void theFirstSupportedLanguageInPreferenceOrderWins(String header, AppLocale expected) {
        assertThat(ExportLanguage.negotiate(header)).isEqualTo(expected);
    }

    @Test
    void noHeaderIsEnglish() {
        assertThat(ExportLanguage.negotiate(null)).isEqualTo(AppLocale.EN);
    }
}
