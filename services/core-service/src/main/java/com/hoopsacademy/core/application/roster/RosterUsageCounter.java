package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.UsageCounter;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Map;

/** Season and team counters of the bound tenant for {@code /internal/usage}. */
@ApplicationScoped
public class RosterUsageCounter implements UsageCounter {

    private final SeasonRepository seasons;
    private final TeamRepository teams;

    public RosterUsageCounter(SeasonRepository seasons, TeamRepository teams) {
        this.seasons = seasons;
        this.teams = teams;
    }

    @Override
    public Map<String, Long> counters() {
        return Map.of("seasons", seasons.count(), "teams", teams.count());
    }
}
