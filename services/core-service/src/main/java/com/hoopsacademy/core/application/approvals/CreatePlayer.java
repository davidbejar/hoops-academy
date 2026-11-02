package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.players.PlayerAccess;
import com.hoopsacademy.core.application.players.PlayerView;
import com.hoopsacademy.core.application.players.PlayerViews;
import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.roster.RosterAuthz;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalPayload;
import com.hoopsacademy.core.domain.approvals.ApprovalPolicy;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import com.hoopsacademy.core.application.members.MemberProvisioning;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import java.util.Optional;

/**
 * Adds a player. ADMIN: ACTIVE at once, optional initial assignment (422 when ineligible), auto-approved audit row.
 * COACH (without ADMIN): the person and player rows are created as PENDING_APPROVAL together with a PENDING
 * ADD_PLAYER request; the initial team, if given, must be one of the coach's own teams. Everyone else: 403.
 */
@ApplicationScoped
public class CreatePlayer {

    /** Contract {@code CreatePlayerRequest}. */
    public record Command(PersonalData data, Optional<TeamId> team, Optional<JerseyNumber> jersey, String note) {}

    private final PlayerAccess access;
    private final RosterAuthz rosterAuthz;
    private final TeamRepository teams;
    private final PlayerLifecycle lifecycle;
    private final ApprovalRepository approvals;
    private final ApprovalOutbox outbox;
    private final ApprovalViews approvalViews;
    private final PlayerViews playerViews;
    private final PlayerRepository players;
    private final PlayerLogin playerLogin;
    private final MemberProvisioning provisioning;
    private final Clock clock;

    public CreatePlayer(PlayerAccess access, RosterAuthz rosterAuthz, TeamRepository teams, PlayerLifecycle lifecycle,
            ApprovalRepository approvals, ApprovalOutbox outbox, ApprovalViews approvalViews, PlayerViews playerViews,
            PlayerRepository players, PlayerLogin playerLogin, MemberProvisioning provisioning, Clock clock) {
        this.access = access;
        this.rosterAuthz = rosterAuthz;
        this.teams = teams;
        this.lifecycle = lifecycle;
        this.approvals = approvals;
        this.outbox = outbox;
        this.approvalViews = approvalViews;
        this.playerViews = playerViews;
        this.players = players;
        this.playerLogin = playerLogin;
        this.provisioning = provisioning;
        this.clock = clock;
    }

    /**
     * An ADMIN-added player with an e-mail gets a login right away (saga: Keycloak, then the transaction); a requested
     * player gets it on approval ({@link ApproveRequest}).
     */
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public PlayerCommandResult handle(Command command) {
        boolean needsApproval = ApprovalPolicy.requiresApproval(access.roles(), ApprovalAction.ADD_PLAYER);
        Optional<NewIdentity> identity = needsApproval ? Optional.empty() : PlayerLogin.identityOf(command.data());
        if (identity.isPresent()) {
            provisioning.requireEmailAvailable(identity.get().email());
        }
        return playerLogin.around(identity, login -> create(command, needsApproval, login));
    }

    @Transactional
    PlayerCommandResult create(Command command, boolean needsApproval, Optional<ProvisionedIdentity> login) {
        command.team().ifPresent(team -> {
            teams.find(team).orElseThrow(() -> new NotFoundException("Team not found"));
            rosterAuthz.requireCoachOf(team);
        });
        PlayerId player = lifecycle.register(command.data(),
                needsApproval ? PlayerStatus.PENDING_APPROVAL : PlayerStatus.ACTIVE);
        ApprovalPayload payload = new ApprovalPayload(command.team().orElse(null), command.jersey().orElse(null),
                blankToNull(command.note()), null);
        ApprovalRequest request;
        if (needsApproval) {
            request = ApprovalRequest.pending(ApprovalAction.ADD_PLAYER, player, payload, access.person(), clock.instant());
            approvals.insert(request);
            outbox.requested(request);
        } else {
            lifecycle.place(player, command.team(), command.jersey());
            request = ApprovalRequest.autoApproved(ApprovalAction.ADD_PLAYER, player, payload, access.person(),
                    clock.instant());
            approvals.insert(request);
            outbox.approved(request);
        }
        Optional<Person> linked = needsApproval ? Optional.empty()
                : login.map(identity -> playerLogin.link(player, identity));
        PlayerView view = playerViews.of(players.find(player).orElseThrow());
        ApprovalView approval = approvalViews.of(request);
        return new PlayerCommandResult(view, approval, playerLogin.temporaryPassword(linked, login));
    }

    private static String blankToNull(String text) {
        return text == null || text.isBlank() ? null : text.strip();
    }
}
