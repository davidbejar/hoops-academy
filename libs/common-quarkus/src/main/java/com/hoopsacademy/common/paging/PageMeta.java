package com.hoopsacademy.common.paging;

/** common.yaml's {@code PageMeta}: the {@code page} member of every list answer. */
public record PageMeta(int page, int size, long totalElements, int totalPages) {

    public static PageMeta of(PageResult<?> result) {
        return new PageMeta(result.page(), result.size(), result.totalElements(), result.totalPages());
    }
}
