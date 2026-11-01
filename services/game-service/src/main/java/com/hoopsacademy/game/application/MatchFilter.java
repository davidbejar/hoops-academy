package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.Instant;

/** Optional list criteria (null = no restriction). */
public record MatchFilter(TeamId teamId, SeasonId seasonId, MatchStatus status, Instant scheduledFrom, Instant scheduledTo) {}
