package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.domain.PlanItem;
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

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Item(UUID id, int position, String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl) {

        static Item from(PlanItem i) {
            return new Item(i.id().value(), i.position(), i.title(), i.description(), i.durationMinutes(), i.sets(),
                    i.repetitions(), i.videoUrl());
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Summary(UUID id, String name, String description, boolean template, UUID sourceTemplateId, int itemCount,
            int totalDurationMinutes, boolean archived) {

        static Summary from(TrainingPlan p) {
            return new Summary(p.id().value(), p.name(), p.description(), p.template(),
                    p.sourcePlanId().map(id -> id.value()).orElse(null), p.itemCount(), p.totalDurationMinutes(),
                    p.archived());
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Plan(UUID id, String name, String description, boolean template, UUID sourceTemplateId, int itemCount,
            int totalDurationMinutes, boolean archived, List<Item> items) {

        static Plan from(TrainingPlan p) {
            Summary s = Summary.from(p);
            return new Plan(s.id(), s.name(), s.description(), s.template(), s.sourceTemplateId(), s.itemCount(),
                    s.totalDurationMinutes(), s.archived(), p.items().stream().map(Item::from).toList());
        }
    }
}
