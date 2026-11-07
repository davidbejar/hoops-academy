package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Builds {@link TeamView}s with two queries for any number of teams. */
@ApplicationScoped
public class TeamViews {

    private final AgeCategoryRepository categories;
    private final TeamPlayerRepository assignments;
    private final PastSeasons pastSeasons;

    public TeamViews(AgeCategoryRepository categories, TeamPlayerRepository assignments, PastSeasons pastSeasons) {
        this.categories = categories;
        this.assignments = assignments;
        this.pastSeasons = pastSeasons;
    }

    public List<TeamView> of(List<Team> teams) {
        Map<AgeCategoryId, AgeCategory> byId = categories.listByRank().stream()
                .collect(Collectors.toMap(AgeCategory::id, Function.identity()));
        Map<TeamId, Long> counts = assignments.countOpenValid(teams.stream().map(Team::id).toList());
        Set<SeasonId> ended = teams.isEmpty() ? Set.of()
                : pastSeasons.ended(teams.stream().map(Team::season).distinct().toList());
        return teams.stream()
                .map(team -> new TeamView(team, byId.get(team.category()), counts.getOrDefault(team.id(), 0L),
                        ended.contains(team.season())))
                .toList();
    }

    public TeamView of(Team team) {
        return of(List.of(team)).get(0);
    }
}
