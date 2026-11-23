package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Query;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;

/**
 * The filter predicates of a list query and their parameters, kept together so that each filter is written once and
 * bound alike to every query that uses the {@link #where()} clause (JPQL or native).
 */
public final class QueryConditions {

    private final List<String> conditions = new ArrayList<>();
    private final Map<String, Object> parameters = new LinkedHashMap<>();

    /** A condition without parameters (a join predicate, a fixed filter). */
    public QueryConditions add(String condition) {
        conditions.add(condition);
        return this;
    }

    public QueryConditions add(String condition, String name, Object value) {
        parameters.put(name, value);
        return add(condition);
    }

    /** {@code condition} with {@code name} bound to {@code parameter(value)}, only when {@code value} is present. */
    public <T> QueryConditions addIf(Optional<T> value, String condition, String name,
            Function<? super T, ?> parameter) {
        value.ifPresent(present -> add(condition, name, parameter.apply(present)));
        return this;
    }

    /** {@code ""} or {@code " where a and b …"}. */
    public String where() {
        return conditions.isEmpty() ? "" : " where " + String.join(" and ", conditions);
    }

    public void bind(Query query) {
        parameters.forEach(query::setParameter);
    }
}
