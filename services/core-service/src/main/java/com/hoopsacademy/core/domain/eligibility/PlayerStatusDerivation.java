package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.core.domain.membership.PlayerStatus;

/** ORPHAN ⇔ an ACTIVE player without a valid open assignment; PENDING_APPROVAL, WITHDRAWN, REJECTED are never touched. */
public final class PlayerStatusDerivation {

    private PlayerStatusDerivation() {}

    public static PlayerStatus derive(PlayerStatus current, boolean hasValidOpenAssignment) {
        return switch (current) {
            case ACTIVE, ORPHAN -> hasValidOpenAssignment ? PlayerStatus.ACTIVE : PlayerStatus.ORPHAN;
            case PENDING_APPROVAL, WITHDRAWN, REJECTED -> current;
        };
    }
}
