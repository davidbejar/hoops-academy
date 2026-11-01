package com.hoopsacademy.core.domain.membership;

/** Lifecycle of a player record (approvals in WP5, orphans in WP4). */
public enum PlayerStatus {
    PENDING_APPROVAL,
    ACTIVE,
    ORPHAN,
    WITHDRAWN
}
