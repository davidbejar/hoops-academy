package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.domain.identity.TemporaryPasswordStatus;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.util.Optional;

/**
 * A member as shown to ADMINs: the person, their player id when they hold the PLAYER role, and the state of their
 * login's temporary password (ADR-0028; NONE without a login).
 */
public record MemberView(Person person, Optional<PlayerId> playerId, TemporaryPasswordStatus temporaryPassword) {}
