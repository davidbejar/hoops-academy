package com.hoopsacademy.core.domain.eligibility;

/** Why a player is INELIGIBLE for a team, in reporting order (the first one is the primary reason). */
public enum EligibilityReason {
    PLAYER_NOT_ACTIVE,
    MISSING_BIRTH_DATE,
    MISSING_GENDER,
    GENDER_POLICY,
    CATEGORY_TOO_LOW,
    PLAY_UP_LIMIT_EXCEEDED
}
