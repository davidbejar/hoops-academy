package com.hoopsacademy.core.adapters.in.internal;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.core.application.authz.MemberAuthz;
import java.util.List;
import java.util.UUID;

/** Contract {@code AuthzContext} (the Java record plus the tenant status). */
public record AuthzContextDto(String sub, UUID personId, UUID tenantId, String tenantStatus, List<String> roles,
        List<UUID> staffTeamIds, List<UUID> linkedPlayerIds, UUID ownPlayerId, List<UUID> playerTeamIds,
        String timezone, List<UUID> historicStaffTeamIds) {

    static AuthzContextDto of(MemberAuthz member) {
        AuthzContext context = member.context();
        return new AuthzContextDto(context.subject(), context.personId(), context.tenantId().value(),
                member.tenantStatus().name(), context.roles().stream().map(Enum::name).sorted().toList(),
                context.staffTeamIds().stream().sorted().toList(), context.linkedPlayerIds().stream().sorted().toList(),
                context.ownPlayerId().orElse(null), context.playerTeamIds().stream().sorted().toList(),
                context.timezone().map(java.time.ZoneId::getId).orElse(null),
                context.historicStaffTeamIds().stream().sorted().toList());
    }
}
