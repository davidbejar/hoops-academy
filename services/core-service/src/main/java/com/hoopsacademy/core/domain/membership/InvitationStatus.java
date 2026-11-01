package com.hoopsacademy.core.domain.membership;

/** NONE = person without login; PENDING = login provisioned, setup outstanding; ACCEPTED = has logged in. */
public enum InvitationStatus {
    NONE,
    PENDING,
    ACCEPTED
}
