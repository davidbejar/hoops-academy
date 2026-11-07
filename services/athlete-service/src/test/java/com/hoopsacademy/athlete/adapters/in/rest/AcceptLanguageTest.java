package com.hoopsacademy.athlete.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.domain.ContentLocale;
import org.junit.jupiter.api.Test;

class AcceptLanguageTest {

    @Test
    void languagesAreTriedInQualityOrder() {
        assertThat(AcceptLanguage.negotiate("en;q=0.5, id")).isEqualTo(ContentLocale.ID);
        assertThat(AcceptLanguage.negotiate("fr-FR, id;q=0.8, es;q=0.9")).isEqualTo(ContentLocale.ES);
        assertThat(AcceptLanguage.negotiate("es-AR,es;q=0.9,en;q=0.8")).isEqualTo(ContentLocale.ES);
        assertThat(AcceptLanguage.negotiate("id, es")).as("equal quality keeps the header order").isEqualTo(ContentLocale.ID);
        assertThat(AcceptLanguage.negotiate(" ID ;Q=1 ")).isEqualTo(ContentLocale.ID);
    }

    @Test
    void refusedMissingAndMalformedEntriesFallBackToEnglish() {
        assertThat(AcceptLanguage.negotiate(null)).isEqualTo(ContentLocale.EN);
        assertThat(AcceptLanguage.negotiate("")).isEqualTo(ContentLocale.EN);
        assertThat(AcceptLanguage.negotiate("*")).isEqualTo(ContentLocale.EN);
        assertThat(AcceptLanguage.negotiate("es;q=0, fr")).as("q=0 means not acceptable").isEqualTo(ContentLocale.EN);
        assertThat(AcceptLanguage.negotiate("es;q=abc")).as("unreadable quality counts as 1").isEqualTo(ContentLocale.ES);
        assertThat(AcceptLanguage.negotiate(",,;q=1,")).isEqualTo(ContentLocale.EN);
    }

    @Test
    void anEntryOfParametersOnlyIsSkipped() {
        assertThat(AcceptLanguage.negotiate(";")).isEqualTo(ContentLocale.EN);
        assertThat(AcceptLanguage.negotiate("es,;")).isEqualTo(ContentLocale.ES);
        assertThat(AcceptLanguage.negotiate(";;, id")).isEqualTo(ContentLocale.ID);
    }

    @Test
    void onlyTheQParameterSetsTheQuality() {
        assertThat(AcceptLanguage.negotiate("es;v=0, id;q=0.5")).isEqualTo(ContentLocale.ES);
    }
}
