package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.eligibility.CaseStatus;
import com.hoopsacademy.core.domain.eligibility.EligibilityCase;
import com.hoopsacademy.core.domain.eligibility.EligibilityCaseId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamId;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/** Eligibility cases of the bound tenant; the team of a case is the team of its assignment. */
public interface EligibilityCaseRepository {

    /** {@code onlyTeams} present = restrict to cases of these teams (staff view). */
    record CaseFilter(Optional<CaseStatus> status, Optional<TeamId> team, Optional<PlayerId> player,
            Optional<Set<TeamId>> onlyTeams) {}

    /** A case with the team of its assignment. */
    record CaseOfTeam(EligibilityCase eligibilityCase, TeamId team) {}

    void insert(EligibilityCase eligibilityCase);

    void update(EligibilityCase eligibilityCase);

    Optional<CaseOfTeam> find(EligibilityCaseId id);

    /** OPEN cases of the player's assignments. */
    List<EligibilityCase> openOfPlayer(PlayerId player);

    PageResult<CaseOfTeam> list(CaseFilter filter, PageRequest page);
}
