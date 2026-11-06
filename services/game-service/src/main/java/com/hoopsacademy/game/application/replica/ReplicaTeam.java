package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;

/** A team with the end of its season (teams of ended seasons grant no access). */
public record ReplicaTeam(TeamId id, SeasonId seasonId, String name, LocalDate seasonEndDate) {}
