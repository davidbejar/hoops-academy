package com.hoopsacademy.core.domain.export;

import com.hoopsacademy.common.problem.DomainRuleViolation;

/** One file, no paging (ADR-0048): an export of more than {@link #MAX_ROWS} rows is refused (422). */
public final class ExportLimit {

    public static final int MAX_ROWS = 10_000;
    public static final String TOO_LARGE = "EXPORT_TOO_LARGE";

    private ExportLimit() {}

    /** @throws DomainRuleViolation {@code EXPORT_TOO_LARGE} when {@code rows} exceeds {@link #MAX_ROWS} */
    public static void requireWithin(long rows) {
        if (rows > MAX_ROWS) {
            throw new DomainRuleViolation("The export would have " + rows + " rows; at most " + MAX_ROWS
                    + " rows fit in one file. Narrow the filter, for example to a shorter date range.", TOO_LARGE);
        }
    }
}
