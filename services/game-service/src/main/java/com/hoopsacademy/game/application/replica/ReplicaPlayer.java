package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.game.domain.PlayerId;
import java.time.LocalDate;
import java.util.Optional;

/** A player as the replica knows it. */
public record ReplicaPlayer(PlayerId id, String displayName, Optional<LocalDate> birthDate, Optional<String> gender) {

    /** core's roster endpoints leave out players without birth date or gender (the contract requires both). */
    public boolean hasBirthDateAndGender() {
        return birthDate.isPresent() && gender.isPresent();
    }
}
