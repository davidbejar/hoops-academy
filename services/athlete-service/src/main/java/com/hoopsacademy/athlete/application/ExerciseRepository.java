package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.Exercise;
import com.hoopsacademy.athlete.domain.ExerciseId;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** Exercises visible to the current tenant: the global catalogue (never written here) and its own exercises. */
public interface ExerciseRepository {

    /** Which part of the catalogue a list shows. */
    enum Scope { GLOBAL, TENANT }

    /**
     * Query for the catalogue, ordered by the shown title then id; {@code query} is a case-insensitive part of that
     * title. For global exercises both use the title in {@code language} (else {@link ContentLocale#FALLBACK}, else the
     * own title). Without a scope both parts are listed; archived exercises only with {@code includeArchived}.
     */
    record Search(Optional<Scope> scope, boolean includeArchived, Optional<String> query, ContentLocale language,
            int page, int size) {}

    /** Inserts or updates an exercise of the current tenant (never a name key or translations). */
    void save(Exercise exercise);

    /** An exercise as stored: a global one with its name key and translations. */
    Optional<Exercise> find(ExerciseId id);

    List<Exercise> findAll(Collection<ExerciseId> ids);

    PageResult<Exercise> search(Search search);
}
