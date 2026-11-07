package com.hoopsacademy.common.paging;

/**
 * The row offset of a 0-based page of at most {@value #MAX_SIZE} rows (SD-01 of the 2026-11 review). {@code page} is
 * only bounded below by the contract, so {@code page * size} used to wrap around {@code int}: a negative offset made
 * Hibernate throw (500) and a wrapped one returned another page. An offset past {@link #BEYOND_ANY_ROW} is clamped to
 * it: no table here holds that many rows, so the page is empty, as any page past the last row is.
 */
public final class PageOffset {

    /** The largest page size any list operation accepts ({@code Size} in {@code common.yaml}). */
    public static final int MAX_SIZE = 200;
    /** Leaves room for {@code offset + size}, which some SQL limit handlers compute, to stay an {@code int}. */
    public static final int BEYOND_ANY_ROW = Integer.MAX_VALUE - MAX_SIZE;

    private PageOffset() {
    }

    public static int of(int page, int size) {
        if (page < 0 || size < 1 || size > MAX_SIZE) {
            throw new IllegalArgumentException("page >= 0 and size 1.." + MAX_SIZE + " required");
        }
        if (page > BEYOND_ANY_ROW / size) {
            return BEYOND_ANY_ROW;
        }
        return page * size;
    }
}
