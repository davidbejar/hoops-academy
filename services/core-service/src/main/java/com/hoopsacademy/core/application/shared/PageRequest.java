package com.hoopsacademy.core.application.shared;

/** A 0-based page of at most {@code size} (1..200) items. */
public record PageRequest(int page, int size) {

    public PageRequest {
        if (page < 0 || size < 1 || size > 200) {
            throw new IllegalArgumentException("page >= 0 and size 1..200 required");
        }
    }

    public int offset() {
        return page * size;
    }
}
