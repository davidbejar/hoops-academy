package com.hoopsacademy.core.application.players;

import com.hoopsacademy.core.application.port.PlayerRepository.PlayerRow;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import java.util.List;

/** Contract {@code Player}: the player with open assignments and the natural category of the current season. */
public record PlayerView(PlayerRow row, AgeCategory naturalCategory, List<Assignment> teams) {

    /** Contract {@code PlayerTeamAssignment}. */
    public record Assignment(TeamId team, String teamName, JerseyNumber jersey, int playUpLevels, boolean valid) {}
}
