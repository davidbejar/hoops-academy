package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.roster.EligibilityQueries.CheckView;
import com.hoopsacademy.core.application.roster.EligibilityQueries.EligibleTeamView;
import com.hoopsacademy.core.domain.eligibility.Eligibility;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Contract {@code EligibilityCheck}. */
public record EligibilityCheckDto(UUID playerId, UUID teamId, LocalDate asOf, String result, Integer playUpLevels,
        List<EligibilityReason> reasons, Integer age, AgeCategoryDto naturalCategory) {

    /** Contract {@code EligibleTeam}. */
    public record EligibleTeamDto(TeamDto team, EligibilityCheckDto eligibility) {

        static EligibleTeamDto of(EligibleTeamView view) {
            return new EligibleTeamDto(TeamDto.of(view.team()), EligibilityCheckDto.of(view.check()));
        }
    }

    static EligibilityCheckDto of(CheckView view) {
        Eligibility verdict = view.evaluation().eligibility();
        String result = switch (verdict) {
            case Eligibility.Eligible e -> "ELIGIBLE";
            case Eligibility.PlayUp p -> "PLAY_UP";
            case Eligibility.Ineligible i -> "INELIGIBLE";
        };
        return new EligibilityCheckDto(view.player().value(), view.team().value(), view.asOf(), result,
                verdict.playUpLevels() > 0 ? verdict.playUpLevels() : null, verdict.reasons(), view.evaluation().age(),
                AgeCategoryDto.of(view.evaluation().naturalCategory()));
    }
}
