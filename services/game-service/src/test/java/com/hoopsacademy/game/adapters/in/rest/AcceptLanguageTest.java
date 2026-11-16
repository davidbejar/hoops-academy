package com.hoopsacademy.game.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.application.sheet.SheetLanguage;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * ADR-0048: the match sheet's labels follow {@code Accept-Language} as core's exports and athlete's templates do
 * (RFC 9110 quality order, header order on ties, {@code q=0} refused, {@code in} is Indonesian, else English).
 */
class AcceptLanguageTest {

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "es|ES",
            "en|EN",
            "id|ID",
            "in|ID",
            "es-AR|ES",
            "ID-id|ID",
            "id_ID|ID",
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
            "es;level=1;q=0.1, id|ID",
            "es;q=0.1;level=1, id;q=0.5|ID",
            "es;q=0, fr|EN",
            "id;q=0.0|EN",
            "  id  ;  q=0.9 , es;q=0.8|ID"})
    void theFirstSupportedLanguageInPreferenceOrderWins(String header, SheetLanguage expected) {
        assertThat(AcceptLanguage.negotiate(header)).isEqualTo(expected);
    }

    @Test
    void noHeaderIsEnglish() {
        assertThat(AcceptLanguage.negotiate(null)).isEqualTo(SheetLanguage.EN);
    }
}
