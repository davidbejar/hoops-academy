package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.AccessDeniedException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;

/** Decisions 53 and 54 (ADR-0041): ad-hoc session plans, quick-added copies and the item search. */
class SessionPlanDomainTest {

    static final Instant NOW = Instant.parse("2026-11-06T10:00:00Z");
    static final Instant LATER = NOW.plusSeconds(60);
    static final Actor COACH = new Actor(PersonId.random(), "Coach Carter");
    static final SessionId SESSION = SessionId.random();
    static final LocalDate DAY = LocalDate.of(2027, 9, 7);

    static PlanItem item(String title) {
        return PlanItem.draft(title, null, 5, null, null, null);
    }

    static TrainingPlan finishing() {
        return TrainingPlan.template(PlanId.random(), "Finishing at the rim", "d", "en", List.of(
                item("Floater"),
                PlanItem.draft("Euro step", "Attack, step through", 6, 2, 8, "https://v").translatedAs(Translations.of(
                        Map.of(ContentLocale.ES, new LocalizedText("Paso europeo", "Ataca y cambia de paso"))))),
                NOW).translatedAs("finishing", Translations.of(
                        Map.of(ContentLocale.ES, new LocalizedText("Finalización", null))));
    }

    // ---- the ad-hoc plan of a session
    @Test
    void aSessionPlanBelongsToItsSessionAndIsNamedAfterTheDayInTheCallersLanguage() {
        TrainingPlan plan = TrainingPlan.forSession(SESSION, DAY, ContentLocale.ES, COACH, NOW);

        assertThat(plan.name()).isEqualTo("Sesión 2027-09-07");
        assertThat(plan.session()).contains(SESSION);
        assertThat(plan.isAdHocFor(SESSION)).isTrue();
        assertThat(plan.isAdHocFor(SessionId.random())).isFalse();
        assertThat(plan.items()).isEmpty();
        assertThat(plan.template()).isFalse();
        assertThat(plan.author()).contains(COACH);
        assertThat(plan.sourcePlanId()).isEmpty();
        assertThat(plan.description()).isNull();
        assertThat(plan.locale()).isEqualTo("es");
        assertThat(List.of(plan.createdAt(), plan.updatedAt())).containsOnly(NOW);
        assertThat(TrainingPlan.forSession(SESSION, DAY, ContentLocale.EN, COACH, NOW).name()).isEqualTo("Session 2027-09-07");
        assertThat(TrainingPlan.forSession(SESSION, DAY, ContentLocale.ID, COACH, NOW).name()).isEqualTo("Sesi 2027-09-07");
    }

    @Test
    void anOrdinaryPlanBelongsToNoSession() {
        TrainingPlan plan = TrainingPlan.create("Week 1", null, COACH, List.of(), NOW);

        assertThat(plan.session()).isEmpty();
        assertThat(plan.isAdHocFor(SESSION)).isFalse();
        assertThat(finishing().session()).isEmpty();
    }

    @Test
    void copyOnWriteTakesTheShownTextsAndPointsAtTheSource() {
        TrainingPlan template = finishing();

        TrainingPlan own = template.localized(ContentLocale.ES).adHocCopyFor(SESSION, COACH, LATER);

        assertThat(own.id()).isNotEqualTo(template.id());
        assertThat(own.template()).isFalse();
        assertThat(own.isAdHocFor(SESSION)).isTrue();
        assertThat(own.name()).isEqualTo("Finalización");
        assertThat(own.sourcePlanId()).contains(template.id());
        assertThat(own.author()).contains(COACH);
        assertThat(own.nameKey()).isEmpty();
        assertThat(own.translations().isEmpty()).isTrue();
        assertThat(own.items()).extracting(PlanItem::title).containsExactly("Floater", "Paso europeo");
        assertThat(own.items()).extracting(PlanItem::id).doesNotContainAnyElementsOf(
                template.items().stream().map(PlanItem::id).toList());
        assertThat(own.updatedAt()).isEqualTo(LATER);
    }

    @Test
    void aCopyOfASessionPlanIsAnOrdinaryPlanAndEditsKeepTheSession() {
        TrainingPlan own = TrainingPlan.forSession(SESSION, DAY, ContentLocale.EN, COACH, NOW);

        assertThat(own.copiedBy(COACH, Optional.empty(), LATER).session()).isEmpty();
        assertThat(own.renamed("Tuesday", LATER).session()).contains(SESSION);
        assertThat(own.localized(ContentLocale.ES).session()).contains(SESSION);
        assertThat(own.withItemAppended(item("Jog"), LATER).session()).contains(SESSION);
    }

    @Test
    void aTemplateNeverBelongsToASession() {
        assertThatThrownBy(() -> new TrainingPlan(PlanId.random(), null, "T", null, null, true, "en", Translations.NONE,
                false, null, SESSION, List.of(), NOW, NOW)).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void onlyItsOwnSessionMayReferenceASessionPlan() {
        TrainingPlan own = TrainingPlan.forSession(SESSION, DAY, ContentLocale.EN, COACH, NOW);

        assertThatCode(() -> own.requireAttachableTo(SESSION)).doesNotThrowAnyException();
        assertThatCode(() -> finishing().requireAttachableTo(SESSION)).doesNotThrowAnyException();
        assertThatThrownBy(() -> own.requireAttachableTo(SessionId.random())).isInstanceOf(TrainingRuleViolation.class)
                .extracting("code").isEqualTo("PLAN_OF_ANOTHER_SESSION");
        assertThatThrownBy(() -> own.requireAttachableTo(null)).isInstanceOf(TrainingRuleViolation.class);
    }

    // ---- quick-add
    @Test
    void copiesAreAppendedInOrderWithFreshIdentitiesAndTheirContent() {
        TrainingPlan target = TrainingPlan.create("Week 1", null, COACH, List.of(item("Jog")), NOW);
        List<PlanItem> sources = finishing().localized(ContentLocale.ES).items();
        PlanItem euro = sources.get(1);

        TrainingPlan changed = target.withCopiesAppended(List.of(euro, sources.get(0), euro), LATER);

        assertThat(changed.items()).extracting(PlanItem::title).containsExactly("Jog", "Paso europeo", "Floater", "Paso europeo");
        assertThat(changed.items()).extracting(PlanItem::position).containsExactly(0, 1, 2, 3);
        assertThat(changed.items().stream().map(PlanItem::id).distinct()).hasSize(4)
                .doesNotContain(euro.id(), sources.get(0).id());
        PlanItem copy = changed.items().get(1);
        assertThat(List.<Object>of(copy.description(), copy.durationMinutes(), copy.sets(), copy.repetitions(), copy.videoUrl()))
                .containsExactly("Ataca y cambia de paso", 6, 2, 8, "https://v");
        assertThat(copy.translations().isEmpty()).isTrue();
        assertThat(changed.updatedAt()).isEqualTo(LATER);
        assertThat(changed.id()).isEqualTo(target.id());
    }

    @Test
    void aTemplateTakesNoCopies() {
        TrainingPlan template = finishing();

        assertThatThrownBy(() -> template.withCopiesAppended(List.of(item("x")), LATER))
                .isInstanceOf(AccessDeniedException.class).extracting("code").isEqualTo("PLAN_IS_TEMPLATE");
    }

    // ---- search
    @Test
    void theSearchMatchesShownItemTitlesIgnoringCase() {
        TrainingPlan plan = TrainingPlan.create("Finishing", null, COACH,
                List.of(item("Euro step"), item("Floater"), item("Step-back")), NOW);

        assertThat(plan.itemsMatching("STEP")).extracting(PlanItem::title).containsExactly("Euro step", "Step-back");
        assertThat(plan.itemsMatching("floater")).extracting(PlanItem::title).containsExactly("Floater");
        assertThat(plan.itemsMatching("finishing")).as("the name is not an item").isEmpty();
        assertThat(finishing().localized(ContentLocale.ES).itemsMatching("EUROPEO")).extracting(PlanItem::title)
                .containsExactly("Paso europeo");
        assertThat(finishing().localized(ContentLocale.EN).itemsMatching("europeo")).isEmpty();
    }

    // ---- the session side
    @Test
    void attachingAPlanMarksTheSessionEditedAndACancelledSessionRefuses() {
        TrainingSession session = TrainingSession.adHoc(new TeamId(java.util.UUID.randomUUID()), NOW, 60, "Court", null, "n");
        PlanId plan = PlanId.random();

        TrainingSession attached = session.withPlan(plan.value());

        assertThat(attached.planId()).isEqualTo(plan.value());
        assertThat(attached.manuallyEdited()).isTrue();
        assertThat(List.<Object>of(attached.id(), attached.startsAt(), attached.endsAt(), attached.location(),
                attached.notes(), attached.status())).containsExactly(session.id(), session.startsAt(), session.endsAt(),
                "Court", "n", SessionStatus.PLANNED);
        assertThatCode(session::requireChangeable).doesNotThrowAnyException();
        TrainingSession cancelled = session.cancelled("rain");
        assertThatThrownBy(cancelled::requireChangeable).isInstanceOf(TrainingStateConflict.class)
                .extracting("code").isEqualTo("SESSION_CANCELLED");
        assertThatThrownBy(() -> cancelled.withPlan(plan.value())).isInstanceOf(TrainingStateConflict.class);
    }
}
