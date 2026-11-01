package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.core.application.me.MeView;
import java.util.List;
import java.util.UUID;

/** Contract {@code Me} (+ {@code Membership}, {@code TenantSummary}, {@code AuthzSummary}). */
public record MeDto(UUID userId, String sub, String email, String displayName, String locale, boolean superAdmin,
        List<MembershipDto> memberships) {

    public record MembershipDto(TenantSummaryDto tenant, UUID personId, List<String> roles, AuthzSummaryDto authz) {}

    public record TenantSummaryDto(UUID id, String slug, String name, String status, boolean hasLogo) {}

    public record AuthzSummaryDto(List<UUID> staffTeamIds, List<UUID> linkedPlayerIds, UUID ownPlayerId,
            List<UUID> playerTeamIds, String timezone) {}

    static MeDto of(MeView me) {
        return new MeDto(me.user().id().value(), me.caller().subject(), me.caller().email(), me.caller().displayName(),
                me.locale().code(), me.caller().superAdmin(), me.memberships().stream().map(MeDto::membership).toList());
    }

    private static MembershipDto membership(MeView.Membership membership) {
        MeView.TenantSummary tenant = membership.tenant();
        AuthzContext authz = membership.authz();
        return new MembershipDto(
                new TenantSummaryDto(tenant.id().value(), tenant.slug(), tenant.name(), tenant.status().name(),
                        tenant.hasLogo()),
                authz.personId(), authz.roles().stream().map(Enum::name).sorted().toList(),
                new AuthzSummaryDto(authz.staffTeamIds().stream().sorted().toList(),
                        authz.linkedPlayerIds().stream().sorted().toList(), authz.ownPlayerId().orElse(null),
                        authz.playerTeamIds().stream().sorted().toList(),
                        authz.timezone().map(java.time.ZoneId::getId).orElse(null)));
    }
}
