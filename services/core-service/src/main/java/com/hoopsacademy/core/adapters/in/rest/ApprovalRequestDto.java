package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.application.approvals.ApprovalView;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalPayload;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalStatus;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Contract {@code ApprovalRequest}. */
public record ApprovalRequestDto(UUID id, ApprovalAction action, ApprovalStatus status, RefDtos.PlayerRef player,
        PayloadDto payload, RefDtos.PersonRef requestedBy, Instant requestedAt, RefDtos.PersonRef decidedBy,
        Instant decidedAt, String decisionNote) {

    /** Contract {@code ApprovalPayload}. */
    public record PayloadDto(UUID teamId, String jerseyNumber, String note, String reason) {}

    /** Contract {@code ApprovalRequestPage}. */
    public record PageDto(List<ApprovalRequestDto> items, PageMetaDto page) {

        static PageDto of(PageResult<ApprovalView> result) {
            return new PageDto(result.items().stream().map(ApprovalRequestDto::of).toList(), PageMetaDto.of(result));
        }
    }

    static ApprovalRequestDto of(ApprovalView view) {
        ApprovalRequest r = view.request();
        ApprovalPayload p = r.payload();
        return new ApprovalRequestDto(r.id().value(), r.action(), r.status(),
                new RefDtos.PlayerRef(r.player().value(), view.playerName()),
                new PayloadDto(p.team() == null ? null : p.team().value(), p.jersey() == null ? null : p.jersey().value(),
                        p.note(), p.reason()),
                new RefDtos.PersonRef(r.requestedBy().value(), view.requesterName()), r.createdAt(),
                r.decidedBy() == null ? null : new RefDtos.PersonRef(r.decidedBy().value(), view.deciderName()),
                r.decidedAt(), r.decisionNote());
    }
}
