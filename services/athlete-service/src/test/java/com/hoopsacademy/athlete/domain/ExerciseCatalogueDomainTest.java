package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.AccessDeniedException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The exercise catalogue (decision 72, ADR-0047): global exercises are read-only and shown in the caller's language,
 * the academy's own are edited and archived; an item copied from an exercise gets its own text and keeps the reference.
 */
class ExerciseCatalogueDomainTest {

    static final Instant NOW = Instant.parse("2026-11-10T10:00:00Z");
    static final Instant LATER = NOW.plusSeconds(60);
    static final ExerciseId COOPER_ID = new ExerciseId(UUID.fromString("0190b6a0-0000-7000-8000-00000000c00b"));

    /** A global exercise in English with a Spanish translation only. */
    static Exercise cooper() {
        return new Exercise(COOPER_ID, "cooper-test", "Cooper test (12 min)", "Run as far as you can", 12, null, null,
                null, true, "en", Translations.of(Map.of(ContentLocale.ES,
                        new LocalizedText("Test de Cooper (12 min)", "Corre la mayor distancia posible"))),
                false, NOW, NOW);
    }

    static Exercise own() {
        return Exercise.create("Zig-zag sprints", "Cones every 3 m", 8, 4, 6, "https://video", NOW);
    }

    // ---- identity and creation
    @Test
    void anExerciseIdPrintsAsItsUuidAndRandomOnesAreFresh() {
        assertThat(COOPER_ID).hasToString("0190b6a0-0000-7000-8000-00000000c00b");
        assertThat(ExerciseId.random()).isNotEqualTo(ExerciseId.random());
        assertThatThrownBy(() -> new ExerciseId(null)).isInstanceOf(NullPointerException.class);
    }

    @Test
    void anAcademyCreatesItsOwnExerciseWithoutKeyOrTranslations() {
        Exercise exercise = own();

        assertThat(List.<Object>of(exercise.title(), exercise.description(), exercise.durationMinutes(), exercise.sets(),
                exercise.repetitions(), exercise.videoUrl())).containsExactly("Zig-zag sprints", "Cones every 3 m", 8, 4, 6,
                "https://video");
        assertThat(exercise.global()).isFalse();
        assertThat(exercise.archived()).isFalse();
        assertThat(exercise.nameKey()).isEmpty();
        assertThat(exercise.translations().isEmpty()).isTrue();
        assertThat(exercise.locale()).isEqualTo("en");
        assertThat(exercise.createdAt()).isEqualTo(NOW);
        assertThat(exercise.updatedAt()).isEqualTo(NOW);
        assertThat(exercise.id()).isNotEqualTo(own().id());
    }

    @Test
    void anExerciseValidatesItsContentLikeAnItem() {
        Exercise smallest = Exercise.create("x", null, 1, 1, 1, null, NOW);
        Exercise largest = Exercise.create("t".repeat(120), null, 480, 100, 1000, null, NOW);

        assertThat(List.of(smallest.durationMinutes(), smallest.sets(), smallest.repetitions())).containsExactly(1, 1, 1);
        assertThat(List.of(largest.durationMinutes(), largest.sets(), largest.repetitions())).containsExactly(480, 100, 1000);
        for (Runnable invalid : List.<Runnable>of(
                () -> Exercise.create(null, null, null, null, null, null, NOW),
                () -> Exercise.create(" ", null, null, null, null, null, NOW),
                () -> Exercise.create("t".repeat(121), null, null, null, null, null, NOW),
                () -> Exercise.create("x", null, 0, null, null, null, NOW),
                () -> Exercise.create("x", null, 481, null, null, null, NOW),
                () -> Exercise.create("x", null, null, 0, null, null, NOW),
                () -> Exercise.create("x", null, null, 101, null, null, NOW),
                () -> Exercise.create("x", null, null, null, 0, null, NOW),
                () -> Exercise.create("x", null, null, null, 1001, null, NOW))) {
            assertThatThrownBy(invalid::run).isInstanceOfSatisfying(TrainingRuleViolation.class,
                    e -> assertThat(e.code()).isEqualTo("INVALID_EXERCISE"));
        }
    }

    @Test
    void onlyAGlobalExerciseCarriesAKeyOrTranslationsAndItIsNeverArchived() {
        Translations spanish = Translations.of(Map.of(ContentLocale.ES, new LocalizedText("Hola", null)));

        assertThatThrownBy(() -> new Exercise(ExerciseId.random(), "key", "T", null, null, null, null, null, false, "en",
                Translations.NONE, false, NOW, NOW)).isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new Exercise(ExerciseId.random(), null, "T", null, null, null, null, null, false, "en",
                spanish, false, NOW, NOW)).isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new Exercise(ExerciseId.random(), "key", "T", null, null, null, null, null, true, "en",
                spanish, true, NOW, NOW)).isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new Exercise(null, null, "T", null, null, null, null, null, false, "en",
                Translations.NONE, false, NOW, NOW)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> new Exercise(ExerciseId.random(), null, "T", null, null, null, null, null, false, "en",
                null, false, NOW, NOW)).isInstanceOf(NullPointerException.class);
        assertThat(cooper().nameKey()).contains("cooper-test");
    }

    // ---- language
    @Test
    void aGlobalExerciseIsShownInTheRequestedLanguageElseInEnglish() {
        Exercise spanish = cooper().localized(ContentLocale.ES);
        Exercise indonesian = cooper().localized(ContentLocale.ID);

        assertThat(List.of(spanish.title(), spanish.description(), spanish.locale()))
                .containsExactly("Test de Cooper (12 min)", "Corre la mayor distancia posible", "es");
        assertThat(List.of(indonesian.title(), indonesian.description(), indonesian.locale()))
                .containsExactly("Cooper test (12 min)", "Run as far as you can", "en");
        assertThat(spanish.translations().isEmpty()).as("shown once, nothing left to translate").isTrue();
        assertThat(spanish.nameKey()).contains("cooper-test");
        assertThat(List.<Object>of(spanish.id(), spanish.durationMinutes(), spanish.global(), spanish.createdAt()))
                .containsExactly(COOPER_ID, 12, true, NOW);
    }

    @Test
    void anAcademyExerciseIsShownAsStored() {
        Exercise exercise = own();

        assertThat(exercise.localized(ContentLocale.ID)).isEqualTo(exercise);
    }

    // ---- editing and archiving
    @Test
    void editingReplacesTheContentAndKeepsTheIdentity() {
        Exercise exercise = own();

        Exercise edited = exercise.edited("Shuttle run", null, 10, null, 3, null, LATER);

        assertThat(List.<Object>of(edited.id(), edited.title(), edited.durationMinutes(), edited.repetitions(),
                edited.createdAt(), edited.updatedAt())).containsExactly(exercise.id(), "Shuttle run", 10, 3, NOW, LATER);
        assertThat(edited.description()).isNull();
        assertThat(edited.sets()).isNull();
        assertThat(edited.videoUrl()).isNull();
        assertThatThrownBy(() -> exercise.edited(" ", null, null, null, null, null, LATER))
                .isInstanceOf(TrainingRuleViolation.class);
    }

    @Test
    void archivingTogglesAndKeepsTheContent() {
        Exercise archived = own().archived(true, LATER);

        assertThat(archived.archived()).isTrue();
        assertThat(archived.updatedAt()).isEqualTo(LATER);
        assertThat(archived.title()).isEqualTo("Zig-zag sprints");
        assertThat(archived.archived(false, LATER).archived()).isFalse();
    }

    @Test
    void aGlobalExerciseIsReadOnly() {
        Exercise global = cooper();

        for (Runnable write : List.<Runnable>of(
                () -> global.edited("x", null, null, null, null, null, LATER),
                () -> global.archived(true, LATER),
                global::requireEditable)) {
            assertThatThrownBy(write::run).isInstanceOfSatisfying(AccessDeniedException.class,
                    e -> assertThat(e.code()).isEqualTo("EXERCISE_IS_GLOBAL"));
        }
        own().requireEditable();
    }

    // ---- copying into a plan
    @Test
    void anItemCopiedFromAnExerciseHasItsTextAndKeepsTheReference() {
        Exercise shown = cooper().localized(ContentLocale.ES);

        PlanItem item = shown.toItem();

        assertThat(List.<Object>of(item.title(), item.description(), item.durationMinutes()))
                .containsExactly("Test de Cooper (12 min)", "Corre la mayor distancia posible", 12);
        assertThat(item.exercise()).contains(COOPER_ID);
        assertThat(item.translations().isEmpty()).isTrue();
        assertThat(item.id()).isNotEqualTo(shown.toItem().id());
        PlanItem fromOwn = own().toItem();
        assertThat(List.<Object>of(fromOwn.sets(), fromOwn.repetitions(), fromOwn.videoUrl()))
                .containsExactly(4, 6, "https://video");
    }

    @Test
    void anArchivedExerciseCannotBeAdded() {
        Exercise archived = own().archived(true, LATER);

        assertThatThrownBy(archived::toItem).isInstanceOfSatisfying(TrainingRuleViolation.class,
                e -> assertThat(e.code()).isEqualTo("EXERCISE_ARCHIVED"));
    }

    @Test
    void theReferenceSurvivesEditingCopyingTranslatingAndLocalizing() {
        PlanItem item = cooper().toItem().translatedAs(Translations.of(Map.of(ContentLocale.ID,
                new LocalizedText("Tes Cooper", null))));

        assertThat(item.edited("My Cooper", null, 15, null, null, null).exercise()).contains(COOPER_ID);
        assertThat(item.localized(ContentLocale.ID, "en").exercise()).contains(COOPER_ID);
        assertThat(item.localized(ContentLocale.ID, "en").title()).isEqualTo("Tes Cooper");
        TrainingPlan plan = TrainingPlan.create("Week", null, null, List.of(item), NOW);
        assertThat(plan.items().get(0).exercise()).contains(COOPER_ID);
        assertThat(plan.withCopiesAppended(List.of(item), LATER).items().get(1).exercise()).contains(COOPER_ID);
        assertThat(plan.copiedBy(null, java.util.Optional.empty(), LATER).items().get(0).exercise()).contains(COOPER_ID);
    }

    @Test
    void anItemWrittenByHandReferencesNoExercise() {
        assertThat(PlanItem.draft("Jog", null, 5, null, null, null).exercise()).isEmpty();
    }
}
