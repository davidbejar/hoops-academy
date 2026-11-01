package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.roster.RolloverSeason.RolloverResult;
import com.hoopsacademy.core.domain.eligibility.EligibilityCaseId;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import java.util.List;
import java.util.UUID;

/** Contract {@code SeasonRolloverResult}. */
public record RolloverResultDto(UUID fromSeasonId, UUID toSeasonId, List<RefDtos.TeamRef> clonedTeams,
        List<OrphanDto> orphans, List<UUID> openedCaseIds) {

    /** Contract {@code Orphan}. */
    public record OrphanDto(RefDtos.PlayerRef player, RefDtos.TeamRef previousTeam, List<EligibilityReason> reasons) {}

    static RolloverResultDto of(RolloverResult result) {
        return new RolloverResultDto(result.from().value(), result.to().value(),
                result.clonedTeams().stream().map(RefDtos.TeamRef::of).toList(),
                result.orphans().stream().map(orphan -> new OrphanDto(
                        new RefDtos.PlayerRef(orphan.player().value(), orphan.displayName()),
                        RefDtos.TeamRef.of(orphan.previousTeam()), orphan.reasons())).toList(),
                result.openedCases().stream().map(EligibilityCaseId::value).toList());
    }
}
