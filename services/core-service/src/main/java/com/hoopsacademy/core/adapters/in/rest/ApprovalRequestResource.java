package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.core.adapters.in.shared.InvalidRequestException;
import com.hoopsacademy.core.application.approvals.ApprovalQueries;
import com.hoopsacademy.core.application.approvals.ApproveRequest;
import com.hoopsacademy.core.application.approvals.CancelRequest;
import com.hoopsacademy.core.application.approvals.RejectRequest;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import com.hoopsacademy.core.domain.approvals.ApprovalStatus;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Approval requests: ADMIN lists/decides all, a COACH lists/gets/cancels their own. */
@Path("/api/core/approval-requests")
@Produces(MediaType.APPLICATION_JSON)
public class ApprovalRequestResource {

    /** Contract {@code ApprovalDecisionRequest}. */
    public record DecisionRequest(@Size(max = 500) String note) {}

    private final ApprovalQueries queries;
    private final ApproveRequest approve;
    private final RejectRequest reject;
    private final CancelRequest cancel;

    public ApprovalRequestResource(ApprovalQueries queries, ApproveRequest approve, RejectRequest reject,
            CancelRequest cancel) {
        this.queries = queries;
        this.approve = approve;
        this.reject = reject;
        this.cancel = cancel;
    }

    @GET
    public ApprovalRequestDto.PageDto list(
            @QueryParam("status") @Pattern(regexp = "PENDING|APPROVED|REJECTED|CANCELLED") String status,
            @QueryParam("action") @Pattern(regexp = "ADD_PLAYER|WITHDRAW_PLAYER") String action,
            @QueryParam("playerId") UUID player,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        ApprovalQueries.Query query = new ApprovalQueries.Query(Optional.ofNullable(status).map(ApprovalStatus::valueOf),
                Optional.ofNullable(action).map(ApprovalAction::valueOf), Optional.ofNullable(player).map(PlayerId::new));
        return ApprovalRequestDto.PageDto.of(queries.list(query, new PageRequest(page, size)));
    }

    @GET
    @Path("/{approvalRequestId}")
    public ApprovalRequestDto get(@PathParam("approvalRequestId") UUID id) {
        return ApprovalRequestDto.of(queries.get(new ApprovalRequestId(id)));
    }

    @POST
    @Path("/{approvalRequestId}/approve")
    @Consumes(MediaType.APPLICATION_JSON)
    public ApprovalRequestDto approve(@PathParam("approvalRequestId") UUID id, @Valid DecisionRequest body) {
        return ApprovalRequestDto.of(approve.handle(new ApprovalRequestId(id), body == null ? null : body.note()));
    }

    @POST
    @Path("/{approvalRequestId}/reject")
    @Consumes(MediaType.APPLICATION_JSON)
    public ApprovalRequestDto reject(@PathParam("approvalRequestId") UUID id, @Valid DecisionRequest body) {
        if (body == null || body.note() == null || body.note().isBlank()) {
            throw new InvalidRequestException(List.of(new Problem.Violation("note", "a rejection needs a note")));
        }
        return ApprovalRequestDto.of(reject.handle(new ApprovalRequestId(id), body.note()));
    }

    @POST
    @Path("/{approvalRequestId}/cancel")
    public ApprovalRequestDto cancel(@PathParam("approvalRequestId") UUID id) {
        return ApprovalRequestDto.of(cancel.handle(new ApprovalRequestId(id)));
    }
}
