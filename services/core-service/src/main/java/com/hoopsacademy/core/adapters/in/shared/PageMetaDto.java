package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.core.application.shared.PageResult;

/** Contract {@code PageMeta}. */
public record PageMetaDto(int page, int size, long totalElements, int totalPages) {

    public static PageMetaDto of(PageResult<?> result) {
        return new PageMetaDto(result.request().page(), result.request().size(), result.totalElements(),
                result.totalPages());
    }
}
