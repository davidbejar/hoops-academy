package com.hoopsacademy.game.application.replica;

import java.util.Optional;

/** An open, valid assignment of a known player to a team. */
public record RosterLine(ReplicaPlayer player, Optional<String> jerseyNumber) {}
