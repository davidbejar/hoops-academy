package com.hoopsacademy.athlete.application;

import java.util.List;
import java.util.function.Function;

/** One page of a list plus the paging figures of the whole result. */
public record PageResult<T>(List<T> items, int page, int size, long totalElements) {

    public int totalPages() {
        return (int) ((totalElements + size - 1) / size);
    }

    public <R> PageResult<R> map(Function<T, R> mapper) {
        return new PageResult<>(items.stream().map(mapper).toList(), page, size, totalElements);
    }
}
