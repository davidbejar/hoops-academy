package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.Exercise;
import com.hoopsacademy.athlete.domain.ExerciseId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;
import java.util.function.UnaryOperator;

/**
 * The exercise catalogue (decision 72, ADR-0047). Every member reads it: the global exercises in the caller's language
 * and the academy's own as stored, archived ones included when asked for or read by id (items keep referencing them).
 * Whoever manages plans (ADMIN, COACH, ASSISTANT_COACH) creates, edits and archives the academy's own; global ones are
 * read-only (403 {@code EXERCISE_IS_GLOBAL}).
 */
@ApplicationScoped
public class ManageExercises {

    /** Exercise content as given by a client. */
    public record ExerciseFields(String title, String description, Integer durationMinutes, Integer sets,
            Integer repetitions, String videoUrl) {}

    /** A partial change: {@code Optional.empty()} = untouched, a present optional holding null = clear. */
    public record ExerciseChange(Optional<String> title, Optional<Optional<String>> description,
            Optional<Optional<Integer>> durationMinutes, Optional<Optional<Integer>> sets,
            Optional<Optional<Integer>> repetitions, Optional<Optional<String>> videoUrl) {}

    private final ExerciseRepository exercises;
    private final PlanAccess access;
    private final TenantClock clock;

    public ManageExercises(ExerciseRepository exercises, PlanAccess access, TenantClock clock) {
        this.exercises = exercises;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public PageResult<Exercise> list(ExerciseRepository.Search search) {
        return exercises.search(search).map(exercise -> exercise.localized(search.language()));
    }

    @Transactional
    public Exercise get(ExerciseId id, ContentLocale language) {
        return load(id).localized(language);
    }

    @Transactional
    public Exercise create(AuthzContext caller, ExerciseFields fields) {
        access.requireStaffRole(caller);
        Exercise exercise = Exercise.create(fields.title(), fields.description(), fields.durationMinutes(), fields.sets(),
                fields.repetitions(), fields.videoUrl(), clock.now());
        exercises.save(exercise);
        return exercise;
    }

    @Transactional
    public Exercise update(AuthzContext caller, ExerciseId id, ExerciseChange change) {
        return edit(caller, id, current -> current.edited(
                change.title().orElse(current.title()),
                Patches.apply(change.description(), current.description()),
                Patches.apply(change.durationMinutes(), current.durationMinutes()),
                Patches.apply(change.sets(), current.sets()),
                Patches.apply(change.repetitions(), current.repetitions()),
                Patches.apply(change.videoUrl(), current.videoUrl()),
                clock.now()));
    }

    @Transactional
    public Exercise setArchived(AuthzContext caller, ExerciseId id, boolean archived) {
        return edit(caller, id, current -> current.archived(archived, clock.now()));
    }

    private Exercise edit(AuthzContext caller, ExerciseId id, UnaryOperator<Exercise> change) {
        access.requireStaffRole(caller);
        Exercise changed = change.apply(load(id));
        exercises.save(changed);
        return changed;
    }

    private Exercise load(ExerciseId id) {
        return exercises.find(id).orElseThrow(() -> new NotFoundException("Exercise not found"));
    }
}
