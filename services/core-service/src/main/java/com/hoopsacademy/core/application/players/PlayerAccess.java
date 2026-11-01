package com.hoopsacademy.core.application.players;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerRow;
import com.hoopsacademy.core.application.port.PlayerRepository.Visibility;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Which players the caller may see. ADMIN: all. Team staff: every player except PENDING_APPROVAL ones they did
 * not request. PARENT / PLAYER: linked / own players, never pending ones. Anyone else: nothing.
 */
@ApplicationScoped
public class PlayerAccess {

    private final TenantContext tenantContext;
    private final ApprovalRepository approvals;

    public PlayerAccess(TenantContext tenantContext, ApprovalRepository approvals) {
        this.tenantContext = tenantContext;
        this.approvals = approvals;
    }

    public Set<TenantRole> roles() {
        return caller().roles();
    }

    public boolean isAdmin() {
        return caller().hasRole(TenantRole.ADMIN);
    }

    public boolean isStaff() {
        return caller().roles().stream().anyMatch(r -> r == TenantRole.COACH || r == TenantRole.ASSISTANT_COACH);
    }

    /** Teams the caller is staff of. */
    public Set<UUID> staffTeams() {
        return caller().staffTeamIds();
    }

    public PersonId person() {
        return new PersonId(caller().personId());
    }

    public Visibility visibility() {
        if (isAdmin()) {
            return Visibility.ALL;
        }
        if (isStaff()) {
            return new Visibility(Optional.empty(), true, Optional.of(person()));
        }
        return new Visibility(Optional.of(relatedPlayers()), true, Optional.empty());
    }

    public boolean canSee(PlayerRow row) {
        PlayerId id = row.summary().id();
        if (isAdmin()) {
            return true;
        }
        boolean pending = row.summary().status() == PlayerStatus.PENDING_APPROVAL;
        if (isStaff()) {
            return !pending || person().equals(approvals.addRequesters(Set.of(id)).get(id));
        }
        return !pending && relatedPlayers().contains(id);
    }

    private Set<PlayerId> relatedPlayers() {
        AuthzContext caller = caller();
        Set<PlayerId> ids = new HashSet<>();
        if (caller.hasRole(TenantRole.PARENT)) {
            caller.linkedPlayerIds().forEach(id -> ids.add(new PlayerId(id)));
        }
        if (caller.hasRole(TenantRole.PLAYER)) {
            caller.ownPlayerId().ifPresent(id -> ids.add(new PlayerId(id)));
        }
        return ids;
    }

    private AuthzContext caller() {
        return tenantContext.authz().orElseThrow(() -> new AccessDeniedException("No tenant membership"));
    }
}
