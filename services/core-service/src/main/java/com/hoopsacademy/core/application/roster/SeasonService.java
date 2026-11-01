package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonChanges;
import com.hoopsacademy.core.domain.roster.SeasonId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.List;

/** Seasons: any member reads, ADMIN writes; seasons never overlap (409 {@code SEASON_OVERLAP}). */
@ApplicationScoped
public class SeasonService {

    public static final String OVERLAP = "SEASON_OVERLAP";

    /** Contract {@code SeasonInput}. */
    public record NewSeason(String name, LocalDate startsOn, LocalDate endsOn, int referenceYear) {}

    /** A season and whether today (tenant time zone) lies within it. */
    public record SeasonView(Season season, boolean current) {}

    private final SeasonRepository seasons;
    private final EligibilityEngine engine;
    private final TenantToday calendar;

    public SeasonService(SeasonRepository seasons, EligibilityEngine engine, TenantToday calendar) {
        this.seasons = seasons;
        this.engine = engine;
        this.calendar = calendar;
    }

    @Transactional
    public List<SeasonView> list() {
        LocalDate today = calendar.today();
        return seasons.listNewestFirst().stream().map(season -> new SeasonView(season, season.isCurrent(today))).toList();
    }

    @Transactional
    public SeasonView get(SeasonId id) {
        return view(find(id));
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public SeasonView create(NewSeason input) {
        Season season = new Season(SeasonId.random(), input.name(), input.startsOn(), input.endsOn(),
                input.referenceYear());
        requireNoOverlap(season);
        seasons.insert(season);
        return view(season);
    }

    /** Changing the dates or the reference year re-evaluates the season's open assignments. */
    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public SeasonView update(SeasonId id, SeasonChanges changes) {
        Season before = find(id);
        Season after = before.apply(changes);
        requireNoOverlap(after);
        seasons.update(after);
        if (!after.equals(before) && (changes.changesReferenceYear() || changes.startsOn().isPresent()
                || changes.endsOn().isPresent())) {
            engine.reevaluateSeason(id);
        }
        return view(after);
    }

    Season find(SeasonId id) {
        return seasons.find(id).orElseThrow(() -> new NotFoundException("Season not found"));
    }

    private void requireNoOverlap(Season season) {
        if (seasons.listNewestFirst().stream().anyMatch(season::overlaps)) {
            throw new ConflictException("The season overlaps another season", OVERLAP);
        }
    }

    private SeasonView view(Season season) {
        return new SeasonView(season, season.isCurrent(calendar.today()));
    }
}
