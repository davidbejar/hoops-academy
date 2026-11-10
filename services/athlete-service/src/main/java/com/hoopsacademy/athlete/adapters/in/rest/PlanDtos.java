package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.application.InvalidRequestException;
import com.hoopsacademy.athlete.application.ManagePlans;
import com.hoopsacademy.athlete.application.QuickAddItems;
import com.hoopsacademy.athlete.domain.ExerciseId;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlanItem;
import com.hoopsacademy.athlete.domain.PlanItemId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.TrainingPlan;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

final class PlanDtos {

    private PlanDtos() {}

    record ItemInput(@NotBlank @Size(max = 120) String title, @Size(max = 4000) String description,
            @Min(1) @Max(480) Integer durationMinutes, @Min(1) @Max(100) Integer sets,
            @Min(1) @Max(1000) Integer repetitions, @Size(max = 2000) String videoUrl) {}

    record CreateRequest(@NotBlank @Size(max = 120) String name, @Size(max = 4000) String description,
            @Size(max = 100) List<@Valid @NotNull ItemInput> items) {

        List<ItemInput> itemsOrEmpty() {
            return items == null ? List.of() : items;
        }
    }

    record CopyRequest(@Size(min = 1, max = 120) String name) {}

    record ReorderRequest(@NotNull @NotEmpty List<@NotNull UUID> itemIds) {}

    /** One copy's source (athlete 3.0.0, PlanItemSource): an exercise, or an item of a readable plan. */
    record ItemSource(UUID exerciseId, UUID planId, UUID itemId) {

        QuickAddItems.ItemSource toSource(int index) {
            if (exerciseId != null && planId == null && itemId == null) {
                return new QuickAddItems.FromExercise(new ExerciseId(exerciseId));
            }
            if (exerciseId == null && planId != null && itemId != null) {
                return new QuickAddItems.FromPlan(new PlanId(planId), new PlanItemId(itemId));
            }
            throw new InvalidRequestException("items[" + index + "]", "INVALID_VALUE",
                    "Give either exerciseId, or planId and itemId");
        }
    }

    /** Quick-add (athlete 2.3.0, sources 3.0.0): 1 to 50 exercises or items of readable plans, copied in this order. */
    record CopyItemsRequest(@NotNull @Size(min = 1, max = 50) List<@NotNull ItemSource> items) {

        List<QuickAddItems.ItemSource> sources() {
            return java.util.stream.IntStream.range(0, items.size()).mapToObj(i -> items.get(i).toSource(i)).toList();
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record ItemMatch(UUID id, UUID planId, String title, UUID exerciseId) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Item(UUID id, int position, String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl, UUID exerciseId) {

        static Item from(PlanItem i) {
            return new Item(i.id().value(), i.position(), i.title(), i.description(), i.durationMinutes(), i.sets(),
                    i.repetitions(), i.videoUrl(), exerciseOf(i));
        }
    }

    private static UUID exerciseOf(PlanItem item) {
        return item.exercise().map(ExerciseId::value).orElse(null);
    }

    /** {@code matchedItems} is null (absent) unless a search matched item titles. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Summary(UUID id, String name, String nameKey, String description, boolean template, UUID sourceTemplateId,
            int itemCount, int totalDurationMinutes, boolean archived, UUID sessionId, List<ItemMatch> matchedItems) {

        static Summary from(TrainingPlan p) {
            return new Summary(p.id().value(), p.name(), p.nameKey().orElse(null), p.description(), p.template(),
                    p.sourcePlanId().map(id -> id.value()).orElse(null), p.itemCount(), p.totalDurationMinutes(),
                    p.archived(), p.session().map(SessionId::value).orElse(null), null);
        }

        static Summary from(ManagePlans.PlanHit hit) {
            Summary s = from(hit.plan());
            List<ItemMatch> matches = hit.matchedItems().stream()
                    .map(i -> new ItemMatch(i.id().value(), s.id(), i.title(), exerciseOf(i))).toList();
            return new Summary(s.id(), s.name(), s.nameKey(), s.description(), s.template(), s.sourceTemplateId(),
                    s.itemCount(), s.totalDurationMinutes(), s.archived(), s.sessionId(),
                    matches.isEmpty() ? null : matches);
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Plan(UUID id, String name, String nameKey, String description, boolean template, UUID sourceTemplateId,
            int itemCount, int totalDurationMinutes, boolean archived, UUID sessionId, List<Item> items) {

        static Plan from(TrainingPlan p) {
            Summary s = Summary.from(p);
            return new Plan(s.id(), s.name(), s.nameKey(), s.description(), s.template(), s.sourceTemplateId(),
                    s.itemCount(), s.totalDurationMinutes(), s.archived(), s.sessionId(),
                    p.items().stream().map(Item::from).toList());
        }
    }
}
