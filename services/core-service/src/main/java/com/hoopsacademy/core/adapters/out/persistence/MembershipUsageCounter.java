package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.UsageCounter;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.HashMap;
import java.util.Map;

/**
 * Member and player counters of the bound tenant: {@code members} (+ {@code membersAdmin}, {@code membersCoach}, …
 * per role), {@code players} (+ {@code playersPendingApproval}, {@code activePlayers}, {@code playersOrphan},
 * {@code playersWithdrawn}). The contract's UsageReport counters are additive.
 */
@ApplicationScoped
class MembershipUsageCounter implements UsageCounter {

    private final PersonRepository persons;
    private final PlayerRepository players;

    MembershipUsageCounter(PersonRepository persons, PlayerRepository players) {
        this.persons = persons;
        this.players = players;
    }

    @Override
    public Map<String, Long> counters() {
        Map<String, Long> counters = new HashMap<>();
        counters.put("members", persons.countActive());
        Map<TenantRole, Long> byRole = persons.countActiveByRole();
        for (TenantRole role : TenantRole.values()) {
            counters.put("members" + camel(role.name()), byRole.getOrDefault(role, 0L));
        }
        Map<PlayerStatus, Long> byStatus = players.countsByStatus();
        counters.put("players", byStatus.values().stream().mapToLong(Long::longValue).sum());
        counters.put("activePlayers", byStatus.getOrDefault(PlayerStatus.ACTIVE, 0L));
        counters.put("playersPendingApproval", byStatus.getOrDefault(PlayerStatus.PENDING_APPROVAL, 0L));
        counters.put("playersOrphan", byStatus.getOrDefault(PlayerStatus.ORPHAN, 0L));
        counters.put("playersWithdrawn", byStatus.getOrDefault(PlayerStatus.WITHDRAWN, 0L));
        counters.put("playersRejected", byStatus.getOrDefault(PlayerStatus.REJECTED, 0L));
        return counters;
    }

    /** ADMIN to Admin, ASSISTANT_COACH to AssistantCoach. */
    private static String camel(String constant) {
        StringBuilder out = new StringBuilder();
        for (String word : constant.split("_")) {
            out.append(word.charAt(0)).append(word.substring(1).toLowerCase(java.util.Locale.ROOT));
        }
        return out.toString();
    }
}
