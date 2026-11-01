package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.domain.MatchRoster;
import java.util.List;
import java.util.UUID;

public record MatchRosterDto(UUID matchId, List<EntryDto> entries) {

    public record EntryDto(UUID playerId, String displayName, String jerseyNumber, boolean isStarter) {}

    static MatchRosterDto from(MatchRoster roster) {
        return new MatchRosterDto(roster.matchId().value(), roster.entries().stream()
                .map(e -> new EntryDto(e.playerId().value(), e.displayName(),
                        e.jerseyNumber() == null ? null : e.jerseyNumber().value(), e.starter()))
                .toList());
    }
}
