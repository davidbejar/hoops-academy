package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Current players and staff of a team, as known by core-service, with the last day of its season ({@code null} when
 * core did not say: an older core; counts as not ended, ADR-0042).
 */
public record TeamRoster(TeamId teamId, String teamName, List<RosterPlayer> players, List<PersonId> staff,
        LocalDate seasonEndDate) {

    public record RosterPlayer(PlayerId playerId, String displayName) {}

    public List<PlayerId> playerIds() {
        return players.stream().map(RosterPlayer::playerId).toList();
    }

    /** The season's last day, when core reported it. */
    public Optional<LocalDate> seasonEnd() {
        return Optional.ofNullable(seasonEndDate);
    }

    public boolean hasPlayer(PlayerId id) {
        return players.stream().anyMatch(p -> p.playerId().equals(id));
    }
}
