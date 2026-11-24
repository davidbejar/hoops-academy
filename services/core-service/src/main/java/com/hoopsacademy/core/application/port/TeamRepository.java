package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.paging.PageRequest;
import com.hoopsacademy.common.paging.PageResult;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/** Teams of the bound tenant. */
public interface TeamRepository {

    /** {@code onlyTeams} empty = no restriction; present = only these ids (e.g. the caller's staffed teams). */
    record TeamFilter(Optional<SeasonId> season, Optional<AgeCategoryId> category, Optional<Set<TeamId>> onlyTeams) {}

    void insert(Team team);

    void update(Team team);

    Optional<Team> find(TeamId id);

    /** @throws NotFoundException "Team not found" (404) */
    default Team require(TeamId id) {
        return find(id).orElseThrow(() -> new NotFoundException("Team not found"));
    }

    List<Team> findAll(Collection<TeamId> ids);

    List<Team> inSeasons(Collection<SeasonId> seasons);

    /** The last day of the season of each of {@code ids}; unknown ids are absent (the membership rule, ADR-0066). */
    Map<TeamId, LocalDate> seasonEnds(Collection<TeamId> ids);

    PageResult<Team> list(TeamFilter filter, PageRequest page);

    boolean nameTaken(SeasonId season, String name, Optional<TeamId> except);

    boolean usesCategory(AgeCategoryId category);

    long count();
}
