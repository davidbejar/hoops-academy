package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.util.Optional;

/** A member as shown to ADMINs: the person plus their player id when they hold the PLAYER role. */
public record MemberView(Person person, Optional<PlayerId> playerId) {}
