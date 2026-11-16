package com.hoopsacademy.core.domain.export;

import com.hoopsacademy.common.problem.DomainRuleViolation;

/**
 * One file, no paging (ADR-0048): an export of more than {@link #MAX_ROWS} rows is refused (422). A printed roster
 * (WP116) also has to fit the sheet's layout: at most {@link #SHEET_MAX_PLAYERS} players, {@link #SHEET_MAX_STAFF}
 * staff and {@link #SHEET_MAX_GUARDIANS} guardians per player (the limits of pdf-service's {@code pdf.yaml}).
 */
public final class ExportLimit {

    public static final int MAX_ROWS = 10_000;
    public static final int SHEET_MAX_PLAYERS = 60;
    public static final int SHEET_MAX_STAFF = 20;
    public static final int SHEET_MAX_GUARDIANS = 4;
    public static final String TOO_LARGE = "EXPORT_TOO_LARGE";

    private ExportLimit() {}

    /** @throws DomainRuleViolation {@code EXPORT_TOO_LARGE} when {@code rows} exceeds {@link #MAX_ROWS} */
    public static void requireWithin(long rows) {
        if (rows > MAX_ROWS) {
            throw new DomainRuleViolation("The export would have " + rows + " rows; at most " + MAX_ROWS
                    + " rows fit in one file. Narrow the filter, for example to a shorter date range.", TOO_LARGE);
        }
    }

    /**
     * @param mostGuardians the guardians of the player who has the most
     * @throws DomainRuleViolation {@code EXPORT_TOO_LARGE} naming the first count that does not fit the sheet
     */
    public static void requirePrintable(int players, int staff, int mostGuardians) {
        requireOnSheet(players, SHEET_MAX_PLAYERS, "players");
        requireOnSheet(staff, SHEET_MAX_STAFF, "staff");
        requireOnSheet(mostGuardians, SHEET_MAX_GUARDIANS, "guardians on one player");
    }

    private static void requireOnSheet(int count, int max, String what) {
        if (count > max) {
            throw new DomainRuleViolation("The printed roster would have " + count + " " + what + "; at most " + max
                    + " fit on the sheet. Export the CSV instead.", TOO_LARGE);
        }
    }
}
