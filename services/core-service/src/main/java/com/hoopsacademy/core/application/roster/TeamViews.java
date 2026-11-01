package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Builds {@link TeamView}s with two queries for any number of teams. */
@ApplicationScoped
public class TeamViews {

    private final AgeCategoryRepository categories;
    private final TeamPlayerRepository assignments;

    public TeamViews(AgeCategoryRepository categories, TeamPlayerRepository assignments) {
        this.categories = categories;
        this.assignments = assignments;
    }

    public List<TeamView> of(List<Team> teams) {
        Map<AgeCategoryId, AgeCategory> byId = categories.listByRank().stream()
                .collect(Collectors.toMap(AgeCategory::id, Function.identity()));
        Map<TeamId, Long> counts = assignments.countOpenValid(teams.stream().map(Team::id).toList());
        return teams.stream()
                .map(team -> new TeamView(team, byId.get(team.category()), counts.getOrDefault(team.id(), 0L)))
                .toList();
    }

    public TeamView of(Team team) {
        return of(List.of(team)).get(0);
    }
}
