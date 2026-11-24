package com.hoopsacademy.common.paging;

import java.util.List;
import java.util.function.Function;

/** One page of a list, the request it answers and the number of matching items in all (LIB-04). Plain Java. */
public record PageResult<T>(List<T> items, PageRequest request, long totalElements) {

    public PageResult {
        items = List.copyOf(items);
    }

    /** The request answered with nothing, without asking the store (e.g. a filter that matches no id). */
    public static <T> PageResult<T> empty(PageRequest request) {
        return new PageResult<>(List.of(), request, 0);
    }

    public int page() {
        return request.page();
    }

    public int size() {
        return request.size();
    }

    public int totalPages() {
        return (int) ((totalElements + request.size() - 1) / request.size());
    }

    public <R> PageResult<R> map(Function<? super T, R> mapper) {
        return new PageResult<>(items.stream().<R>map(mapper).toList(), request, totalElements);
    }
}
