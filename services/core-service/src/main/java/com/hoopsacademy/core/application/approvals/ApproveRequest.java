package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.players.PlayerAccess;
import com.hoopsacademy.core.domain.approvals.ApprovalPayload;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalStatus;
import java.util.Optional;

/**
 * ADMIN approves a PENDING request and the action runs in the same transaction. ADD_PLAYER: the player becomes
 * ACTIVE and the optional team assignment goes through the eligibility-checked command — if that fails (422) the
 * whole transaction rolls back and the request stays PENDING. WITHDRAW_PLAYER: as the direct admin withdrawal.
 */
@ApplicationScoped
public class ApproveRequest {

    private final DecideRequest decisions;
    private final PlayerLifecycle lifecycle;
    private final ApprovalOutbox outbox;
    private final ApprovalViews views;
    private final PlayerAccess access;
    private final PlayerLogin playerLogin;
    private final PersonRepository persons;
    private final PlayerRepository players;
    private final Clock clock;

    ApproveRequest(DecideRequest decisions, PlayerLifecycle lifecycle, ApprovalOutbox outbox, ApprovalViews views,
            PlayerAccess access, PlayerLogin playerLogin, PersonRepository persons, PlayerRepository players,
            Clock clock) {
        this.decisions = decisions;
        this.lifecycle = lifecycle;
        this.outbox = outbox;
        this.views = views;
        this.access = access;
        this.playerLogin = playerLogin;
        this.persons = persons;
        this.players = players;
        this.clock = clock;
    }

    /**
     * Approving the ADD of a player with an e-mail and no login provisions the login first (saga, see
     * {@link PlayerLogin}); a failing invitation leaves the request PENDING.
     */
    @RequiresTenantRole(TenantRole.ADMIN)
    public ApprovalView handle(ApprovalRequestId id, String note) {
        return playerLogin.around(loginToInvite(id), login -> decide(id, note, login));
    }

    @Transactional
    Optional<NewIdentity> loginToInvite(ApprovalRequestId id) {
        ApprovalRequest request = decisions.load(id);
        if (request.action() != ApprovalAction.ADD_PLAYER || request.status() != ApprovalStatus.PENDING) {
            return Optional.empty();
        }
        return players.personOf(request.player()).flatMap(persons::find)
                .filter(person -> person.userId() == null)
                .flatMap(person -> PlayerLogin.identityOf(person.data()));
    }

    @Transactional
    ApprovalView decide(ApprovalRequestId id, String note, Optional<ProvisionedIdentity> login) {
        ApprovalRequest decided = decisions.store(decisions.load(id).approve(access.person(), note, clock.instant()));
        ApprovalPayload payload = decided.payload();
        switch (decided.action()) {
            case ADD_PLAYER -> {
                lifecycle.admit(decided.player(), Optional.ofNullable(payload.team()),
                        Optional.ofNullable(payload.jersey()));
                outbox.approved(decided);
                login.ifPresent(identity -> playerLogin.link(decided.player(), identity));
            }
            case WITHDRAW_PLAYER -> {
                lifecycle.withdraw(decided.player(), access.person());
                outbox.withdrawn(decided);
            }
        }
        ApprovalView view = views.of(decided);
        playerLogin.sendSetupEmail(login);
        return view;
    }
}
