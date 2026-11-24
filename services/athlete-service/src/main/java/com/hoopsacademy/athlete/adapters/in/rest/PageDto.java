package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.common.paging.PageMeta;
import com.hoopsacademy.common.paging.PageResult;
import java.util.List;
import java.util.function.Function;

/** Page envelope {@code {items, page}} of the contract. */
record PageDto<T>(List<T> items, PageMeta page) {

    static <D, T> PageDto<T> of(PageResult<D> result, Function<D, T> mapper) {
        return new PageDto<>(result.items().stream().map(mapper).toList(), PageMeta.of(result));
    }
}
