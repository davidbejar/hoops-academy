package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** Team assignments (team_player rows) of the bound tenant. */
public interface TeamPlayerRepository {

    /** @throws com.hoopsacademy.common.problem.ConflictException on a concurrent duplicate open assignment/jersey */
    void insert(TeamPlayer assignment);

    void update(TeamPlayer assignment);

    Optional<TeamPlayer> find(TeamPlayerId id);

    Optional<TeamPlayer> findOpen(TeamId team, PlayerId player);

    /** Open (valid or invalidated) assignments of a team, or all of its assignments with {@code includeLeft}. */
    List<TeamPlayer> ofTeam(TeamId team, boolean includeLeft);

    List<TeamPlayer> openValidOfTeams(Collection<TeamId> teams);

    List<TeamPlayer> openOfPlayers(Collection<PlayerId> players);

    boolean jerseyTaken(TeamId team, JerseyNumber jersey, Optional<TeamPlayerId> except);

    Map<TeamId, Long> countOpenValid(Collection<TeamId> teams);
}
