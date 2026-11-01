package com.hoopsacademy.core.domain.eligibility;

/** How an eligibility case was resolved. */
public enum CaseResolution {
    /** The player was assigned to another (eligible) team; the invalid assignment is closed. */
    REASSIGNED,
    /** The invalid assignment was closed. */
    REMOVED_FROM_TEAM,
    /** Only the decision is recorded; the assignment stays invalid. */
    DISMISSED
}
