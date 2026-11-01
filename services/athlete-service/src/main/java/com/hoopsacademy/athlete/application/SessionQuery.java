package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.SessionStatus;
import com.hoopsacademy.athlete.domain.TeamId;
import java.time.Instant;
import java.util.Optional;
import java.util.Set;

/** Filter of the session list: {@code teams == null} means every team; the window is [from, to). */
public record SessionQuery(Set<TeamId> teams, Instant from, Instant to, Optional<SessionStatus> status, int page, int size) {}
