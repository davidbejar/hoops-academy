package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.membership.Gender;

/** Which players a team admits. */
public enum GenderPolicy {
    MALE,
    FEMALE,
    MIXED;

    public boolean admits(Gender gender) {
        return this == MIXED || name().equals(gender.name());
    }
}
