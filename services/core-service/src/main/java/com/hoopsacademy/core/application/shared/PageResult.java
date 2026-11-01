package com.hoopsacademy.core.application.shared;

import java.util.List;
import java.util.function.Function;

/** One page of a result plus the total number of matching items. */
public record PageResult<T>(List<T> items, PageRequest request, long totalElements) {

    public PageResult {
        items = List.copyOf(items);
    }

    public int totalPages() {
        return (int) ((totalElements + request.size() - 1) / request.size());
    }

    public <R> PageResult<R> map(Function<T, R> mapper) {
        return new PageResult<>(items.stream().map(mapper).toList(), request, totalElements);
    }
}
