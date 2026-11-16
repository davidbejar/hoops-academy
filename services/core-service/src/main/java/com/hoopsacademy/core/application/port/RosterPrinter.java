package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.export.RosterPrint;

/**
 * Renders a printed team roster (WP116, ADR-0051 §3: pdf-service). Implementations never log what they send.
 *
 * @see com.hoopsacademy.common.problem.UpstreamUnavailableException thrown when the sheet cannot be rendered now
 */
public interface RosterPrinter {

    /** @return the PDF document */
    byte[] print(RosterPrint roster);
}
