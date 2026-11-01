package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.players.PlayerAccess;
import com.hoopsacademy.core.application.players.PlayerQueries;
import com.hoopsacademy.core.application.players.PlayerViews;
import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerRow;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalPayload;
import com.hoopsacademy.core.domain.approvals.ApprovalPolicy;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.List;

/**
 * Withdraws a player. ADMIN: immediately (assignments closed, OPEN cases resolved, status WITHDRAWN) with an
 * auto-approved audit row. COACH (without ADMIN): a PENDING WITHDRAW_PLAYER request for a player on one of the
 * coach's own teams; the player stays as is until an ADMIN approves.
 */
@ApplicationScoped
public class WithdrawPlayer {

    public static final String NOT_WITHDRAWABLE = "PLAYER_NOT_WITHDRAWABLE";

    private final PlayerAccess access;
    private final PlayerQueries queries;
    private final PlayerLifecycle lifecycle;
    private final TeamPlayerRepository assignments;
    private final ApprovalRepository approvals;
    private final ApprovalOutbox outbox;
    private final ApprovalViews approvalViews;
    private final PlayerViews playerViews;
    private final PlayerRepository players;
    private final Clock clock;

    public WithdrawPlayer(PlayerAccess access, PlayerQueries queries,
            PlayerLifecycle lifecycle, TeamPlayerRepository assignments, ApprovalRepository approvals,
            ApprovalOutbox outbox, ApprovalViews approvalViews, PlayerViews playerViews, PlayerRepository players,
            Clock clock) {
        this.access = access;
        this.queries = queries;
        this.lifecycle = lifecycle;
        this.assignments = assignments;
        this.approvals = approvals;
        this.outbox = outbox;
        this.approvalViews = approvalViews;
        this.playerViews = playerViews;
        this.players = players;
        this.clock = clock;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public PlayerCommandResult handle(PlayerId id, String reason) {
        boolean needsApproval = ApprovalPolicy.requiresApproval(access.roles(), ApprovalAction.WITHDRAW_PLAYER);
        PlayerRow row = queries.visible(id);
        requireWithdrawable(row.summary().status());
        ApprovalPayload payload = ApprovalPayload.reason(reason == null || reason.isBlank() ? null : reason.strip());
        ApprovalRequest request;
        if (needsApproval) {
            requireOwnPlayer(id);
            request = ApprovalRequest.pending(ApprovalAction.WITHDRAW_PLAYER, id, payload, access.person(), clock.instant());
            approvals.insert(request);
            outbox.requested(request);
        } else {
            lifecycle.withdraw(id, access.person());
            request = ApprovalRequest.autoApproved(ApprovalAction.WITHDRAW_PLAYER, id, payload, access.person(),
                    clock.instant());
            approvals.insert(request);
            outbox.withdrawn(request);
        }
        return new PlayerCommandResult(playerViews.of(players.find(id).orElseThrow()), approvalViews.of(request));
    }

    private static void requireWithdrawable(PlayerStatus status) {
        if (status == PlayerStatus.PENDING_APPROVAL) {
            throw new ConflictException("The player is still awaiting approval; reject or cancel that request instead",
                    NOT_WITHDRAWABLE);
        }
        if (status == PlayerStatus.WITHDRAWN) {
            throw new ConflictException("The player is already withdrawn", NOT_WITHDRAWABLE);
        }
    }

    /** A COACH may only ask to withdraw players on a team they staff. */
    private void requireOwnPlayer(PlayerId id) {
        List<TeamPlayer> open = assignments.openOfPlayers(List.of(id));
        if (open.stream().noneMatch(a -> access.staffTeams().contains(a.team().value()))) {
            throw new AccessDeniedException("A coach may only withdraw players of their own teams");
        }
    }
}
