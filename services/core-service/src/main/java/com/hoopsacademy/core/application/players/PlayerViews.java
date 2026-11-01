package com.hoopsacademy.core.application.players;

import com.hoopsacademy.core.application.players.PlayerView.Assignment;
import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerRow;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import com.hoopsacademy.core.application.roster.TenantToday;
import com.hoopsacademy.core.domain.eligibility.AgeFunction;
import com.hoopsacademy.core.domain.eligibility.CategoryLadder;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Builds {@link PlayerView}s for any number of players with a fixed number of queries. */
@ApplicationScoped
public class PlayerViews {

    private final TeamPlayerRepository assignments;
    private final TeamRepository teams;
    private final SeasonRepository seasons;
    private final AgeCategoryRepository categories;
    private final TenantSettingsRepository settings;
    private final TenantToday calendar;

    public PlayerViews(TeamPlayerRepository assignments, TeamRepository teams, SeasonRepository seasons,
            AgeCategoryRepository categories, TenantSettingsRepository settings, TenantToday calendar) {
        this.assignments = assignments;
        this.teams = teams;
        this.seasons = seasons;
        this.categories = categories;
        this.settings = settings;
        this.calendar = calendar;
    }

    public List<PlayerView> of(List<PlayerRow> rows) {
        if (rows.isEmpty()) {
            return List.of();
        }
        List<TeamPlayer> open = assignments.openOfPlayers(rows.stream().map(r -> r.summary().id()).toList());
        Map<TeamId, Team> teamsById = teams.findAll(open.stream().map(TeamPlayer::team).distinct().toList()).stream()
                .collect(Collectors.toMap(Team::id, Function.identity()));
        Map<PlayerId, List<Assignment>> byPlayer = open.stream().collect(Collectors.groupingBy(TeamPlayer::player,
                Collectors.mapping(a -> new Assignment(a.team(), teamsById.get(a.team()).name(), a.jersey(),
                        a.playUpLevels(), a.isValid()), Collectors.toList())));
        Naturals naturals = naturals();
        return rows.stream().map(row -> new PlayerView(row, naturals.of(row.summary().birthDate()),
                byPlayer.getOrDefault(row.summary().id(), List.of()))).toList();
    }

    public PlayerView of(PlayerRow row) {
        return of(List.of(row)).get(0);
    }

    private Naturals naturals() {
        LocalDate today = calendar.today();
        Optional<Season> current = seasons.notEndedOn(today).stream().filter(s -> s.isCurrent(today)).findFirst();
        if (current.isEmpty()) {
            return new Naturals(null, null, null, today);
        }
        AgeFunction age = AgeFunction.of(settings.findCurrent().orElseThrow().ageRule());
        return new Naturals(CategoryLadder.of(categories.listByRank()), age, current.get(), today);
    }

    /** Natural category of a birth date in the current season; none when there is no current season. */
    private record Naturals(CategoryLadder ladder, AgeFunction age, Season season, LocalDate today) {

        AgeCategory of(LocalDate birthDate) {
            if (season == null || birthDate == null) {
                return null;
            }
            return ladder.naturalFor(age.ageOf(birthDate, season.referenceYear(), today)).orElse(null);
        }
    }
}
