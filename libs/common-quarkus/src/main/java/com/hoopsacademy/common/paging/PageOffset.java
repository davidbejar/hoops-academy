package com.hoopsacademy.common.paging;

/** The row offset of a 0-based page (SD-01). Red stub: the guard follows in the next commit. */
public final class PageOffset {

    public static final int MAX_SIZE = 200;
    public static final int BEYOND_ANY_ROW = Integer.MAX_VALUE - MAX_SIZE;

    private PageOffset() {
    }

    public static int of(int page, int size) {
        return page * size;
    }
}
