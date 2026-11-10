package com.hoopsacademy.core.application.export;

import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.export.ExportLimit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * Reads a paged, newest-first list to its end for an export (ADR-0048): the first page's total is checked against the
 * row limit before anything else is read; then pages follow until a short one. A row written while the export runs
 * pushes older rows onto the next page, so a row read twice is kept once (by {@code key}); rows written after the
 * first page may be missing, never doubled.
 */
public final class ExportPages {

    public static final int PAGE_SIZE = 200;

    private ExportPages() {}

    public static <T, K> List<T> readAll(Function<PageRequest, PageResult<T>> reader, Function<T, K> key) {
        PageResult<T> page = reader.apply(new PageRequest(0, PAGE_SIZE));
        ExportLimit.requireWithin(page.totalElements());
        Map<K, T> rows = new LinkedHashMap<>();
        for (int next = 1; ; next++) {
            page.items().forEach(item -> rows.putIfAbsent(key.apply(item), item));
            ExportLimit.requireWithin(rows.size());
            if (page.items().size() < PAGE_SIZE) {
                return List.copyOf(rows.values());
            }
            page = reader.apply(new PageRequest(next, PAGE_SIZE));
        }
    }
}
