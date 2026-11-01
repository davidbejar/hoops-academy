package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.application.roster.EligibilityCaseService.CaseView;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.eligibility.CaseResolution;
import com.hoopsacademy.core.domain.eligibility.CaseStatus;
import com.hoopsacademy.core.domain.eligibility.EligibilityCase;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Contract {@code EligibilityCase}. */
public record EligibilityCaseDto(UUID id, RefDtos.PlayerRef player, RefDtos.TeamRef team, EligibilityReason reason,
        CaseStatus status, Instant openedAt, Instant resolvedAt, RefDtos.PersonRef resolvedBy, CaseResolution resolution,
        String resolutionNote) {

    /** Contract {@code EligibilityCasePage}. */
    public record PageDto(List<EligibilityCaseDto> items, PageMetaDto page) {

        static PageDto of(PageResult<CaseView> result) {
            return new PageDto(result.items().stream().map(EligibilityCaseDto::of).toList(), PageMetaDto.of(result));
        }
    }

    static EligibilityCaseDto of(CaseView view) {
        EligibilityCase c = view.eligibilityCase();
        return new EligibilityCaseDto(c.id().value(), new RefDtos.PlayerRef(c.player().value(), view.playerName()),
                new RefDtos.TeamRef(view.team().value(), view.teamName()), c.reason(), c.status(), c.openedAt(),
                c.resolvedAt(), c.resolvedBy() == null ? null : new RefDtos.PersonRef(c.resolvedBy().value(),
                        view.resolverName()), c.resolution(), c.resolutionNote());
    }
}
