package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;

/** Decision 43: global templates are shown in the caller's language (es / en / id), tenant plans as stored. */
class TemplateLanguageTest {

    static final Instant NOW = Instant.parse("2026-11-06T10:00:00Z");
    static final Actor COACH = new Actor(PersonId.random(), "Coach Carter");

    static PlanItem item(String title, String description, Translations translations) {
        return PlanItem.draft(title, description, 5, null, null, null).translatedAs(translations);
    }

    /** An English template with a Spanish translation only (no Indonesian), like a partially translated seed. */
    static TrainingPlan formShooting() {
        return TrainingPlan.template(PlanId.random(), "Form shooting", "Mechanics first", "en", List.of(
                item("One-hand form shots", "Shooting hand only", Translations.of(Map.of(
                        ContentLocale.ES, new LocalizedText("Tiros a una mano", "Solo la mano de tiro")))),
                item("Catch-and-shoot", null, Translations.NONE)), NOW)
                .translatedAs("form-shooting", Translations.of(Map.of(
                        ContentLocale.ES, new LocalizedText("Técnica de tiro", "Primero la mecánica"))));
    }

    // ---- negotiation
    @Test
    void theFirstSupportedLanguageInPreferenceOrderWins() {
        assertThat(ContentLocale.negotiate(List.of("id", "en"))).isEqualTo(ContentLocale.ID);
        assertThat(ContentLocale.negotiate(List.of("fr", "es", "en"))).isEqualTo(ContentLocale.ES);
        assertThat(ContentLocale.negotiate(List.of("en-GB", "es"))).isEqualTo(ContentLocale.EN);
        assertThat(ContentLocale.negotiate(List.of("ES-ar"))).isEqualTo(ContentLocale.ES);
        assertThat(ContentLocale.negotiate(List.of("in"))).as("legacy Java code of Indonesian").isEqualTo(ContentLocale.ID);
    }

    @Test
    void absentWildcardOrUnsupportedLanguagesFallBackToEnglish() {
        assertThat(ContentLocale.negotiate(List.of())).isEqualTo(ContentLocale.EN);
        assertThat(ContentLocale.negotiate(List.of("*"))).isEqualTo(ContentLocale.EN);
        assertThat(ContentLocale.negotiate(List.of("fr", "de-DE", ""))).isEqualTo(ContentLocale.EN);
        assertThat(ContentLocale.FALLBACK).isEqualTo(ContentLocale.EN);
        assertThat(ContentLocale.fromCode(null)).isEmpty();
        assertThat(ContentLocale.fromCode("id")).contains(ContentLocale.ID);
        assertThat(ContentLocale.ID.code()).isEqualTo("id");
    }

    // ---- texts
    @Test
    void aLocalizedTextNeedsATitleOfOneTo120Characters() {
        assertThat(new LocalizedText("t".repeat(120), null).title()).hasSize(120);
        assertThatThrownBy(() -> new LocalizedText(" ", "d")).isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> new LocalizedText(null, "d")).isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> new LocalizedText("t".repeat(121), "d")).isInstanceOf(TrainingRuleViolation.class);
    }

    @Test
    void translationsAreLookedUpByLanguage() {
        Translations es = Translations.of(Map.of(ContentLocale.ES, new LocalizedText("Hola", null)));

        assertThat(es.in(ContentLocale.ES)).contains(new LocalizedText("Hola", null));
        assertThat(es.in(ContentLocale.ID)).isEmpty();
        assertThat(es.isEmpty()).isFalse();
        assertThat(Translations.NONE.isEmpty()).isTrue();
        assertThat(Translations.of(null)).isEqualTo(Translations.NONE);
        assertThat(es.texts()).containsOnlyKeys(ContentLocale.ES);
    }

    // ---- resolution
    @Test
    void aTemplateIsShownInTheRequestedLanguage() {
        TrainingPlan spanish = formShooting().localized(ContentLocale.ES);

        assertThat(spanish.name()).isEqualTo("Técnica de tiro");
        assertThat(spanish.description()).isEqualTo("Primero la mecánica");
        assertThat(spanish.locale()).isEqualTo("es");
        assertThat(spanish.nameKey()).contains("form-shooting");
        assertThat(spanish.items()).extracting(PlanItem::title).containsExactly("Tiros a una mano", "Catch-and-shoot");
        assertThat(spanish.items().get(0).description()).isEqualTo("Solo la mano de tiro");
        assertThat(spanish.items()).extracting(PlanItem::position).containsExactly(0, 1);
        assertThat(spanish.template()).isTrue();
    }

    @Test
    void aMissingTranslationFallsBackToEnglish() {
        TrainingPlan template = formShooting();

        TrainingPlan indonesian = template.localized(ContentLocale.ID);
        TrainingPlan english = template.localized(ContentLocale.EN);

        assertThat(indonesian.name()).isEqualTo("Form shooting");
        assertThat(indonesian.description()).isEqualTo("Mechanics first");
        assertThat(indonesian.locale()).isEqualTo("en");
        assertThat(indonesian.items()).extracting(PlanItem::title).containsExactly("One-hand form shots", "Catch-and-shoot");
        assertThat(english.name()).isEqualTo("Form shooting");
        assertThat(english.items().get(0).title()).isEqualTo("One-hand form shots");
    }

    @Test
    void anEnglishTranslationIsUsedWhenTheBaseTextIsInAnotherLanguage() {
        TrainingPlan spanishBase = TrainingPlan.template(PlanId.random(), "Rondo", null, "es", List.of(), NOW)
                .translatedAs("rondo", Translations.of(Map.of(ContentLocale.EN, new LocalizedText("Keep-away", null))));

        assertThat(spanishBase.localized(ContentLocale.ID).name()).isEqualTo("Keep-away");
        assertThat(spanishBase.localized(ContentLocale.ID).locale()).isEqualTo("en");
        assertThat(spanishBase.localized(ContentLocale.ES).name()).isEqualTo("Rondo");
        assertThat(spanishBase.localized(ContentLocale.ES).locale()).isEqualTo("es");
    }

    @Test
    void aTenantPlanKeepsItsStoredTextsInEveryLanguage() {
        TrainingPlan mine = TrainingPlan.create("Mi plan", "Martes", COACH, List.of(item("Bote", null, Translations.NONE)), NOW);

        for (ContentLocale language : ContentLocale.values()) {
            assertThat(mine.localized(language)).isEqualTo(mine);
        }
        assertThat(mine.nameKey()).isEmpty();
        assertThat(mine.translations().isEmpty()).isTrue();
    }

    @Test
    void onlyTemplatesCarryTranslations() {
        TrainingPlan mine = TrainingPlan.create("Mi plan", null, COACH, List.of(), NOW);

        assertThatThrownBy(() -> mine.translatedAs("key", Translations.NONE)).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void aCopyKeepsTheTextsItWasCopiedWithAndDropsTheTranslations() {
        TrainingPlan template = formShooting();

        TrainingPlan copy = template.localized(ContentLocale.ES).copiedBy(COACH, Optional.empty(), NOW);

        assertThat(copy.name()).isEqualTo("Técnica de tiro");
        assertThat(copy.description()).isEqualTo("Primero la mecánica");
        assertThat(copy.locale()).isEqualTo("es");
        assertThat(copy.template()).isFalse();
        assertThat(copy.nameKey()).isEmpty();
        assertThat(copy.translations().isEmpty()).isTrue();
        assertThat(copy.sourcePlanId()).contains(template.id());
        assertThat(copy.items()).extracting(PlanItem::title).containsExactly("Tiros a una mano", "Catch-and-shoot");
        assertThat(copy.items()).allSatisfy(i -> assertThat(i.translations().isEmpty()).isTrue());
        assertThat(copy.localized(ContentLocale.ID).name()).isEqualTo("Técnica de tiro");
    }

    @Test
    void editingAnItemDropsItsTranslations() {
        PlanItem translated = item("Jog", null, Translations.of(Map.of(ContentLocale.ES, new LocalizedText("Trote", null))));

        assertThat(translated.edited("Run", null, 5, null, null, null).translations().isEmpty()).isTrue();
    }
}
