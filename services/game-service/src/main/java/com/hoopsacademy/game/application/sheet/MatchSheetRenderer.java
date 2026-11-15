package com.hoopsacademy.game.application.sheet;

/**
 * Renders a match sheet as PDF (the internal pdf-service, ADR-0051 §3, ADR-0052). The sheet holds players' names: an
 * implementation never logs it nor puts it on a span or in an exception message.
 */
public interface MatchSheetRenderer {

    /**
     * @throws com.hoopsacademy.common.problem.UpstreamUnavailableException when the renderer is not configured, cannot
     *         be reached in time, or refuses or fails the sheet (503 {@code UPSTREAM_UNAVAILABLE})
     */
    PdfFile render(MatchSheet sheet);
}
