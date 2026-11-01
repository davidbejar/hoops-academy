package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/** Teams of the bound tenant. */
public interface TeamRepository {

    /** {@code onlyTeams} empty = no restriction; present = only these ids (e.g. the caller's staffed teams). */
    record TeamFilter(Optional<SeasonId> season, Optional<AgeCategoryId> category, Optional<Set<TeamId>> onlyTeams) {}

    void insert(Team team);

    void update(Team team);

    Optional<Team> find(TeamId id);

    List<Team> findAll(Collection<TeamId> ids);

    List<Team> inSeasons(Collection<SeasonId> seasons);

    PageResult<Team> list(TeamFilter filter, PageRequest page);

    boolean nameTaken(SeasonId season, String name, Optional<TeamId> except);

    boolean usesCategory(AgeCategoryId category);

    long count();
}
