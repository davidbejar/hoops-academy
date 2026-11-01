package com.hoopsacademy.core.domain.membership;

/**
 * Lifecycle of a player record (approvals in WP5, orphans in WP4). WITHDRAWN (left the academy, or the requester
 * cancelled the ADD_PLAYER request) and REJECTED (an admin rejected the ADD_PLAYER request; never admitted) are final.
 */
public enum PlayerStatus {
    PENDING_APPROVAL,
    ACTIVE,
    ORPHAN,
    WITHDRAWN,
    REJECTED;

    /** Not (yet) admitted: hidden from everybody but admins and the requesting coach. */
    public boolean awaitingOrRefused() {
        return this == PENDING_APPROVAL || this == REJECTED;
    }
}
