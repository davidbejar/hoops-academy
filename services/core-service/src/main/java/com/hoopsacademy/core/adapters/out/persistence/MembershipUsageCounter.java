package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.UsageCounter;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Map;

/** Member and player counters of the bound tenant (WP4 adds teams/seasons with its own counter). */
@ApplicationScoped
class MembershipUsageCounter implements UsageCounter {

    private final PersonRepository persons;
    private final PlayerRepository players;

    MembershipUsageCounter(PersonRepository persons, PlayerRepository players) {
        this.persons = persons;
        this.players = players;
    }

    @Override
    public Map<String, Long> counters() {
        return Map.of(
                "members", persons.countActive(),
                "players", players.count(),
                "activePlayers", players.countByStatus(PlayerStatus.ACTIVE));
    }
}
