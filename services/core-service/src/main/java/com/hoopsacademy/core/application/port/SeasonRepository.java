package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/** Seasons of the bound tenant. */
public interface SeasonRepository {

    /** @throws com.hoopsacademy.common.problem.ConflictException {@code SEASON_OVERLAP} (database trigger) */
    void insert(Season season);

    /** @throws com.hoopsacademy.common.problem.ConflictException {@code SEASON_OVERLAP} (database trigger) */
    void update(Season season);

    Optional<Season> find(SeasonId id);

    List<Season> listNewestFirst();

    /** Seasons whose last day is {@code day} or later (current and upcoming). */
    List<Season> notEndedOn(LocalDate day);

    long count();
}
