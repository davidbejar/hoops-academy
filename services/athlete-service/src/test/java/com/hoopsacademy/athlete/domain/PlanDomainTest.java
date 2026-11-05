package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.NotFoundException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class PlanDomainTest {

    static final Instant NOW = Instant.parse("2026-11-03T10:00:00Z");
    static final Actor COACH = new Actor(PersonId.random(), "Coach Carter");

    static PlanItem item(String title, Integer minutes) {
        return PlanItem.draft(title, null, minutes, null, null, null);
    }

    static TrainingPlan plan(PlanItem... items) {
        return TrainingPlan.create("Shooting week", "desc", COACH, List.of(items), NOW);
    }

    // ---- items and plans
    @Test
    void planNumbersItemsFromZeroAndSumsDurations() {
        TrainingPlan plan = plan(item("Warm-up", 10), item("Shots", 20), item("Stretch", null));

        assertThat(plan.items()).extracting(PlanItem::position).containsExactly(0, 1, 2);
        assertThat(plan.itemCount()).isEqualTo(3);
        assertThat(plan.totalDurationMinutes()).isEqualTo(30);
        assertThat(plan.template()).isFalse();
        assertThat(plan.author()).contains(COACH);
    }

    @Test
    void itemAndPlanValidateTheirFields() {
        assertThatThrownBy(() -> item(" ", 5)).isInstanceOf(TrainingRuleViolation.class)
                .extracting("code").isEqualTo("INVALID_ITEM");
        assertThatThrownBy(() -> item("x", 0)).isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> item("x", 481)).isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> TrainingPlan.create(" ", null, COACH, List.of(), NOW))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("INVALID_PLAN");
    }

    @Test
    void itemLimitsAreInclusiveAndEveryCountIsChecked() {
        PlanItem smallest = PlanItem.draft("x", null, 1, 1, 1, null);
        PlanItem largest = PlanItem.draft("t".repeat(120), null, 480, 100, 1000, null);

        assertThat(List.of(smallest.durationMinutes(), smallest.sets(), smallest.repetitions())).containsExactly(1, 1, 1);
        assertThat(List.of(largest.durationMinutes(), largest.sets(), largest.repetitions())).containsExactly(480, 100, 1000);
        for (Runnable invalid : List.<Runnable>of(
                () -> PlanItem.draft(null, null, null, null, null, null),
                () -> PlanItem.draft("t".repeat(121), null, null, null, null, null),
                () -> PlanItem.draft("x", null, null, 0, null, null),
                () -> PlanItem.draft("x", null, null, 101, null, null),
                () -> PlanItem.draft("x", null, null, null, 0, null),
                () -> PlanItem.draft("x", null, null, null, 1001, null))) {
            assertThatThrownBy(invalid::run).isInstanceOfSatisfying(TrainingRuleViolation.class,
                    e -> assertThat(e.code()).isEqualTo("INVALID_ITEM"));
        }
    }

    @Test
    void planNamesAreOneTo120Characters() {
        assertThat(TrainingPlan.create("n".repeat(120), null, COACH, List.of(), NOW).name()).hasSize(120);
        assertThatThrownBy(() -> TrainingPlan.create(null, null, COACH, List.of(), NOW))
                .isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> TrainingPlan.create("n".repeat(121), null, COACH, List.of(), NOW))
                .isInstanceOf(TrainingRuleViolation.class);
    }

    @Test
    void renamingAndDescribingKeepTheItems() {
        TrainingPlan plan = plan(item("Warm-up", 10));

        TrainingPlan renamed = plan.renamed("Free throws", NOW.plusSeconds(1));
        TrainingPlan described = renamed.described("Ten in a row", NOW.plusSeconds(2));

        assertThat(described.name()).isEqualTo("Free throws");
        assertThat(described.description()).isEqualTo("Ten in a row");
        assertThat(described.items()).isEqualTo(plan.items());
        assertThat(described.updatedAt()).isEqualTo(NOW.plusSeconds(2));
    }

    @Test
    void itemsAreFoundByIdAndAnUnknownItemCannotBeReplaced() {
        PlanItem warmUp = item("Warm-up", 10);
        TrainingPlan plan = plan(warmUp);

        assertThat(plan.item(warmUp.id())).isEqualTo(plan.items().get(0));
        assertThatThrownBy(() -> plan.withItemReplaced(item("Stranger", 5), NOW))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void appendingAnItemPutsItLast() {
        TrainingPlan plan = plan(item("A", 5)).withItemAppended(item("B", 7), NOW.plusSeconds(60));

        assertThat(plan.items()).extracting(PlanItem::title).containsExactly("A", "B");
        assertThat(plan.items().get(1).position()).isEqualTo(1);
        assertThat(plan.updatedAt()).isEqualTo(NOW.plusSeconds(60));
    }

    @Test
    void removingAnItemClosesTheGap() {
        TrainingPlan plan = plan(item("A", 5), item("B", 5), item("C", 5));
        PlanItemId b = plan.items().get(1).id();

        TrainingPlan changed = plan.withoutItem(b, NOW);

        assertThat(changed.items()).extracting(PlanItem::title).containsExactly("A", "C");
        assertThat(changed.items()).extracting(PlanItem::position).containsExactly(0, 1);
        assertThatThrownBy(() -> changed.withoutItem(b, NOW)).hasMessageContaining("Plan item not found");
    }

    @Test
    void replacingAnItemKeepsItsPosition() {
        TrainingPlan plan = plan(item("A", 5), item("B", 5));
        PlanItem edited = plan.items().get(1).edited("B2", "new", 9, 3, 10, null);

        TrainingPlan changed = plan.withItemReplaced(edited, NOW);

        assertThat(changed.items().get(1).title()).isEqualTo("B2");
        assertThat(changed.items().get(1).position()).isEqualTo(1);
        assertThat(changed.totalDurationMinutes()).isEqualTo(14);
    }

    @Test
    void reorderMustBeAPermutationOfTheItems() {
        TrainingPlan plan = plan(item("A", 5), item("B", 5), item("C", 5));
        List<PlanItemId> ids = plan.items().stream().map(PlanItem::id).toList();

        TrainingPlan reordered = plan.reordered(List.of(ids.get(2), ids.get(0), ids.get(1)), NOW);

        assertThat(reordered.items()).extracting(PlanItem::title).containsExactly("C", "A", "B");
        assertThat(reordered.items()).extracting(PlanItem::position).containsExactly(0, 1, 2);
        assertThatThrownBy(() -> plan.reordered(List.of(ids.get(0), ids.get(1)), NOW))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("ITEM_ORDER_MISMATCH");
        assertThatThrownBy(() -> plan.reordered(List.of(ids.get(0), ids.get(0), ids.get(1)), NOW))
                .isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> plan.reordered(List.of(ids.get(0), ids.get(1), PlanItemId.random()), NOW))
                .isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> plan.reordered(List.of(ids.get(0), ids.get(1), ids.get(2), ids.get(0)), NOW))
                .isInstanceOf(TrainingRuleViolation.class);
    }

    // ---- templates and copy-on-use
    @Test
    void aTemplateRefusesEveryEditButCanBeCopied() {
        TrainingPlan template = TrainingPlan.template(PlanId.random(), "Warm-up", "d", "en", List.of(item("Jog", 5)), NOW);

        assertThat(template.template()).isTrue();
        assertThatThrownBy(template::requireEditable).isInstanceOf(AccessDeniedException.class)
                .extracting("code").isEqualTo("PLAN_IS_TEMPLATE");
        assertThatThrownBy(() -> template.renamed("x", NOW)).isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> template.withItemAppended(item("x", 1), NOW)).isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> template.archived(true, NOW)).isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void copyIsIndependentFromItsSource() {
        TrainingPlan template = TrainingPlan.template(PlanId.random(), "Warm-up", "d", "en",
                List.of(item("Jog", 5), item("Stretch", 3)), NOW);

        TrainingPlan copy = template.copiedBy(COACH, Optional.empty(), NOW.plusSeconds(5));

        assertThat(copy.id()).isNotEqualTo(template.id());
        assertThat(copy.template()).isFalse();
        assertThat(copy.name()).isEqualTo("Warm-up");
        assertThat(copy.sourcePlanId()).contains(template.id());
        assertThat(copy.author()).contains(COACH);
        assertThat(copy.items()).extracting(PlanItem::title).containsExactly("Jog", "Stretch");
        assertThat(copy.items()).extracting(PlanItem::id).doesNotContainAnyElementsOf(
                template.items().stream().map(PlanItem::id).toList());
        assertThat(copy.locale()).isEqualTo("en");
        assertThat(template.copiedBy(COACH, Optional.of("My warm-up"), NOW).name()).isEqualTo("My warm-up");
    }

    @Test
    void archivedPlansToggle() {
        TrainingPlan plan = plan(item("A", 5));

        assertThat(plan.archived(true, NOW).archived()).isTrue();
        assertThat(plan.archived(true, NOW).archived(false, NOW).archived()).isFalse();
    }

    // ---- assignments
    @Test
    void assignmentNeedsExactlyOneTarget() {
        PlanId plan = PlanId.random();
        LocalDate due = LocalDate.of(2026, 12, 1);

        assertThat(PlanAssignment.create(plan, Optional.of(TeamId.random()), Optional.empty(), due, "n", COACH, NOW).teamId())
                .isPresent();
        assertThat(PlanAssignment.create(plan, Optional.empty(), Optional.of(PlayerId.random()), due, null, COACH, NOW).playerId())
                .isPresent();
        assertThatThrownBy(() -> PlanAssignment.create(plan, Optional.empty(), Optional.empty(), due, null, COACH, NOW))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("ASSIGNMENT_TARGET_REQUIRED");
        assertThatThrownBy(() -> PlanAssignment.create(plan, Optional.of(TeamId.random()), Optional.of(PlayerId.random()), due, null, COACH, NOW))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("ASSIGNMENT_TARGET_AMBIGUOUS");
    }

    @Test
    void assignmentTargetsTheRosterOrTheSinglePlayer() {
        PlayerId a = PlayerId.random();
        PlayerId b = PlayerId.random();
        PlanAssignment forTeam = PlanAssignment.create(PlanId.random(), Optional.of(TeamId.random()), Optional.empty(),
                LocalDate.of(2026, 12, 1), null, COACH, NOW);
        PlanAssignment forPlayer = PlanAssignment.create(PlanId.random(), Optional.empty(), Optional.of(a),
                LocalDate.of(2026, 12, 1), null, COACH, NOW);

        assertThat(forTeam.targets(List.of(a, b))).containsExactlyInAnyOrder(a, b);
        assertThat(forPlayer.targets(List.of(b))).containsExactly(a);
    }

    // ---- completion and progress
    @Test
    void progressCountsEachStatusAndWhoHasNotAnswered() {
        PlayerId done = PlayerId.random();
        PlayerId partial = PlayerId.random();
        PlayerId none = PlayerId.random();
        AssignmentId assignment = AssignmentId.random();
        List<PlanCompletion> completions = List.of(
                PlanCompletion.record(assignment, done, CompletionStatus.DONE, null, COACH, NOW),
                PlanCompletion.record(assignment, partial, CompletionStatus.PARTIAL, "half", COACH, NOW),
                // someone who left the team after answering is not a target any more and is not counted
                PlanCompletion.record(assignment, PlayerId.random(), CompletionStatus.DONE, null, COACH, NOW));

        PlanProgress progress = PlanProgress.of(assignment, List.of(done, partial, none), completions);

        assertThat(progress.counts()).containsEntry(CompletionStatus.DONE, 1).containsEntry(CompletionStatus.PARTIAL, 1)
                .containsEntry(CompletionStatus.NOT_DONE, 0);

        assertThat(progress.total()).isEqualTo(3);
        assertThat(progress.count(CompletionStatus.DONE)).isEqualTo(1);
        assertThat(progress.count(CompletionStatus.PARTIAL)).isEqualTo(1);
        assertThat(progress.count(CompletionStatus.NOT_DONE)).isZero();
        assertThat(progress.notRecorded()).isEqualTo(1);
        assertThat(progress.players()).hasSize(3);
        assertThat(progress.players().get(2).completion()).isEmpty();
    }

    @Test
    void theLastOfSeveralCompletionsOfAPlayerCounts() {
        AssignmentId assignment = AssignmentId.random();
        PlayerId player = PlayerId.random();
        PlanCompletion earlier = PlanCompletion.record(assignment, player, CompletionStatus.PARTIAL, null, COACH, NOW);
        PlanCompletion later = PlanCompletion.record(assignment, player, CompletionStatus.DONE, null, COACH, NOW);

        PlanProgress progress = PlanProgress.of(assignment, List.of(player), List.of(earlier, later));

        assertThat(progress.players().get(0).completion()).contains(later);
    }

    @Test
    void recordingAgainReplacesTheStatusAndKeepsTheIdentity() {
        AssignmentId assignment = AssignmentId.random();
        PlayerId player = PlayerId.random();
        PlanCompletion first = PlanCompletion.record(assignment, player, CompletionStatus.PARTIAL, null, COACH, NOW);

        PlanCompletion second = first.changedTo(CompletionStatus.DONE, "all done", COACH, NOW.plusSeconds(9));

        assertThat(second.id()).isEqualTo(first.id());
        assertThat(second.status()).isEqualTo(CompletionStatus.DONE);
        assertThat(second.markedAt()).isEqualTo(NOW.plusSeconds(9));
    }
}
