package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import java.time.LocalDate;
import java.util.Objects;

/** What the evaluator needs to know about a player; birth date and gender may be missing in the data. */
public record EligibilityCandidate(PlayerId player, PlayerStatus status, LocalDate birthDate, Gender gender) {

    public EligibilityCandidate {
        Objects.requireNonNull(player, "player");
        Objects.requireNonNull(status, "status");
    }

    /** ACTIVE and ORPHAN players may be assigned; PENDING_APPROVAL and WITHDRAWN may not. */
    public boolean isActive() {
        return status == PlayerStatus.ACTIVE
                || status == PlayerStatus.ORPHAN;
    }
}
