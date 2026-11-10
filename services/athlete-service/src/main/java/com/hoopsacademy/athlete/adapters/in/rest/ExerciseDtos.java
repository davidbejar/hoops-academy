package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.athlete.application.ManageExercises;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

final class ExerciseDtos {

    private ExerciseDtos() {}

    record Input(@NotBlank @Size(max = 120) String title, @Size(max = 4000) String description,
            @Min(1) @Max(480) Integer durationMinutes, @Min(1) @Max(100) Integer sets,
            @Min(1) @Max(1000) Integer repetitions, @Size(max = 2000) String videoUrl) {

        ManageExercises.ExerciseFields fields() {
            return new ManageExercises.ExerciseFields(title, description, durationMinutes, sets, repetitions, videoUrl);
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Exercise(UUID id, String nameKey, String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl, boolean global, boolean archived) {

        static Exercise from(com.hoopsacademy.athlete.domain.Exercise e) {
            return new Exercise(e.id().value(), e.nameKey().orElse(null), e.title(), e.description(),
                    e.durationMinutes(), e.sets(), e.repetitions(), e.videoUrl(), e.global(), e.archived());
        }
    }
}
