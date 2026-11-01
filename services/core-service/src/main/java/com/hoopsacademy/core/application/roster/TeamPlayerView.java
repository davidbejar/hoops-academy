package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.TeamPlayer;

/** An assignment with the player's display name and current status. */
public record TeamPlayerView(TeamPlayer assignment, String playerName, PlayerStatus playerStatus) {}
