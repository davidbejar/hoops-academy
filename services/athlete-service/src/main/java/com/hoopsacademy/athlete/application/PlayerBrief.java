package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PlayerId;
import java.time.LocalDate;
import java.util.Optional;

/** Minimal player data from core-service; birth date and gender (for fitness norms) are empty when core does not know them. */
public record PlayerBrief(PlayerId playerId, String displayName, String status, Optional<LocalDate> birthDate,
        Optional<Gender> gender) {}
