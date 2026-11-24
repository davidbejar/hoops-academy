package com.hoopsacademy.common.i18n;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * ADR-0048 / ADR-0039, once for core's exports, game's match sheet and athlete's templates (X-07): entries by
 * descending quality (RFC 9110 §12.5.4), header order on ties, {@code q=0} refused, an unreadable quality counts as 1,
 * {@code in} is Indonesian; the first of es / en / id wins, anything else is English. Never fails.
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
            "en;q=0.5, id|ID",
            "fr-FR, id;q=0.8, es;q=0.9|ES",
            "es-AR,es;q=0.9,en;q=0.8|ES",
            "id, es|ID",
            "es;q=0, id|ID",
            "es;q=1.0, en;q=1.0|ES",
            "en;q=1, es|EN",
            "fr, de|EN",
            "*|EN",
            "''|EN",
            ";q=1, es|ES",
            "es;q=abc, id;q=0.5|ES",
            "es; Q=0.1, id;q=0.5|ID",
            " ID ;Q=1 |ID",
            "es;level=1;q=0.1, id|ID",
            "es;q=0.1;level=1, id;q=0.5|ID",
            "es;v=0, id;q=0.5|ES",
            "es;q=0, fr|EN",
            "id;q=0.0|EN",
            "  id  ;  q=0.9 , es;q=0.8|ID",
            "',,;q=1,'|EN",
            ";|EN",
            "'es,;'|ES",
            "';;, id'|ID"})
    void theFirstSupportedLanguageInPreferenceOrderWins(String header, AppLanguage expected) {
        assertThat(AcceptLanguage.negotiate(header)).isEqualTo(expected);
    }

    @Test
    void noHeaderIsEnglish() {
        assertThat(AcceptLanguage.negotiate(null)).isEqualTo(AppLanguage.FALLBACK).isEqualTo(AppLanguage.EN);
    }

    @ParameterizedTest
    @CsvSource({"es, ES", "ES, ES", "es-AR, ES", "en_GB, EN", "in, ID", "' id ', ID"})
    void aTagNamesItsLanguageByItsPrimarySubtag(String tag, AppLanguage expected) {
        assertThat(AppLanguage.fromTag(tag)).contains(expected);
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "fr", "*", "e", "esp"})
    void anUnsupportedTagNamesNoLanguage(String tag) {
        assertThat(AppLanguage.fromTag(tag)).isEmpty();
    }

    @Test
    void aMissingTagNamesNoLanguage() {
        assertThat(AppLanguage.fromTag(null)).isEmpty();
    }

    @Test
    void theCodesAreTheContractsLocales() {
        assertThat(AppLanguage.values()).extracting(AppLanguage::code).containsExactly("es", "en", "id");
    }
}
