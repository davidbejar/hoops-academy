package com.hoopsacademy.common.paging;

/** A 0-based page of at most {@code size} (1..{@value PageOffset#MAX_SIZE}) items: common.yaml's Page and Size. */
public record PageRequest(int page, int size) {

    public PageRequest {
        if (page < 0 || size < 1 || size > PageOffset.MAX_SIZE) {
            throw new IllegalArgumentException("page >= 0 and size 1.." + PageOffset.MAX_SIZE + " required");
        }
    }

    /** {@code page * size}, clamped where it would overflow (SD-01): such a page is empty. */
    public int offset() {
        return PageOffset.of(page, size);
    }
}
