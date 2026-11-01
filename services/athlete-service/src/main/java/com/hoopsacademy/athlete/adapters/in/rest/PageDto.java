package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.PageResult;
import java.util.List;
import java.util.function.Function;

/** Page envelope {@code {items, page}} of the contract. */
record PageDto<T>(List<T> items, Meta page) {

    record Meta(int page, int size, long totalElements, int totalPages) {}

    static <D, T> PageDto<T> of(PageResult<D> result, Function<D, T> mapper) {
        return new PageDto<>(result.items().stream().map(mapper).toList(),
                new Meta(result.page(), result.size(), result.totalElements(), result.totalPages()));
    }
}
