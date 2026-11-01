package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import java.util.List;

/** Current players and staff of a team, as known by core-service. */
public record TeamRoster(TeamId teamId, String teamName, List<RosterPlayer> players, List<PersonId> staff) {

    public record RosterPlayer(PlayerId playerId, String displayName) {}

    public List<PlayerId> playerIds() {
        return players.stream().map(RosterPlayer::playerId).toList();
    }

    public boolean hasPlayer(PlayerId id) {
        return players.stream().anyMatch(p -> p.playerId().equals(id));
    }
}
