package com.hoopsacademy.core.application.shared;

import com.hoopsacademy.common.paging.PageOffset;

/** A 0-based page of at most {@code size} (1..200) items. */
public record PageRequest(int page, int size) {

    public PageRequest {
        if (page < 0 || size < 1 || size > PageOffset.MAX_SIZE) {
            throw new IllegalArgumentException("page >= 0 and size 1..200 required");
        }
    }

    /** {@code page * size}, clamped where it would overflow (SD-01): such a page is empty. */
    public int offset() {
        return PageOffset.of(page, size);
    }
}
