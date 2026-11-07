package com.hoopsacademy.common.tenancy;

import static com.hoopsacademy.common.tenancy.TenantRole.ADMIN;
import static com.hoopsacademy.common.tenancy.TenantRole.ASSISTANT_COACH;
import static com.hoopsacademy.common.tenancy.TenantRole.COACH;
import static com.hoopsacademy.common.tenancy.TenantRole.PARENT;
import static com.hoopsacademy.common.tenancy.TenantRole.PLAYER;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.EnumSet;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AuthzContextTest {

    private static final TenantId TENANT = TenantId.random();
    private static final UUID TEAM = UUID.randomUUID();
    private static final UUID OTHER_TEAM = UUID.randomUUID();
    private static final UUID CHILD = UUID.randomUUID();
    private static final UUID SELF = UUID.randomUUID();

    private static AuthzContext context(Set<TenantRole> roles) {
        return new AuthzContext("sub-1", UUID.randomUUID(), TENANT, roles, Set.of(TEAM), Set.of(CHILD), Optional.of(SELF));
    }

    @Test
    void hasAnyRoleUsesAnyOfSemantics() {
        var coachAndParent = context(EnumSet.of(COACH, PARENT));

        assertThat(coachAndParent.hasAnyRole(Set.of(ADMIN, PARENT))).isTrue();
        assertThat(coachAndParent.hasAnyRole(Set.of(ADMIN, PLAYER))).isFalse();
        assertThat(coachAndParent.hasAnyRole(Set.of())).isFalse();
        assertThat(coachAndParent.hasRole(COACH)).isTrue();
    }

    @Test
    void teamStaffRequiresAStaffRoleAndATeamStaffRow() {
        assertThat(context(EnumSet.of(COACH)).isStaffOf(TEAM)).isTrue();
        assertThat(context(EnumSet.of(ASSISTANT_COACH)).isStaffOf(TEAM)).isTrue();
        assertThat(context(EnumSet.of(COACH)).isStaffOf(OTHER_TEAM)).isFalse();
        assertThat(context(EnumSet.of(PARENT)).isStaffOf(TEAM)).isFalse();
    }

    @Test
    void guardianRequiresParentRoleAndALink() {
        assertThat(context(EnumSet.of(PARENT)).isGuardianOf(CHILD)).isTrue();
        assertThat(context(EnumSet.of(PARENT)).isGuardianOf(UUID.randomUUID())).isFalse();
        assertThat(context(EnumSet.of(COACH)).isGuardianOf(CHILD)).isFalse();
    }

    @Test
    void selfRequiresPlayerRoleAndOwnPlayerId() {
        assertThat(context(EnumSet.of(PLAYER)).isSelf(SELF)).isTrue();
        assertThat(context(EnumSet.of(PLAYER)).isSelf(CHILD)).isFalse();
        assertThat(context(EnumSet.of(PARENT)).isSelf(SELF)).isFalse();
        var withoutOwnPlayer = new AuthzContext("s", UUID.randomUUID(), TENANT, EnumSet.of(PLAYER), Set.of(), Set.of(), Optional.empty());
        assertThat(withoutOwnPlayer.isSelf(SELF)).isFalse();
    }

    @Test
    void isDefensivelyCopiedAndImmutable() {
        var roles = EnumSet.of(COACH);
        var teams = new HashSet<>(Set.of(TEAM));
        var ctx = new AuthzContext("s", UUID.randomUUID(), TENANT, roles, teams, Set.of(), Optional.empty());

        roles.add(ADMIN);
        teams.clear();

        assertThat(ctx.roles()).containsExactly(COACH);
        assertThat(ctx.staffTeamIds()).containsExactly(TEAM);
        assertThatThrownBy(() -> ctx.roles().add(ADMIN)).isInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    void emptyRoleSetIsAllowedForPlainMembers() {
        var member = new AuthzContext("s", UUID.randomUUID(), TENANT, Set.of(), Set.of(), Set.of(), Optional.empty());

        assertThat(member.roles()).isEmpty();
        assertThat(member.hasAnyRole(EnumSet.allOf(TenantRole.class))).isFalse();
    }

    @Test
    void requiresSubjectAndTenant() {
        assertThatThrownBy(() -> new AuthzContext(null, null, TENANT, Set.of(), Set.of(), Set.of(), Optional.empty()))
                .isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> new AuthzContext("s", null, null, Set.of(), Set.of(), Set.of(), Optional.empty()))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    void carriesTheTenantZoneAndThePlayerTeamsWhenCoreReportsThem() {
        UUID childTeam = UUID.randomUUID();
        var parent = new AuthzContext("s", UUID.randomUUID(), TENANT, EnumSet.of(PARENT), Set.of(), Set.of(CHILD),
                Optional.empty(), Set.of(childTeam), Optional.of(java.time.ZoneId.of("Asia/Jakarta")));

        assertThat(parent.playerTeamIds()).containsExactly(childTeam);
        assertThat(parent.timezone()).contains(java.time.ZoneId.of("Asia/Jakarta"));
        assertThat(parent.isPlayerTeam(childTeam)).isTrue();
        assertThat(parent.isPlayerTeam(TEAM)).isFalse();
    }

    @Test
    void theShortFormHasNoPlayerTeamsAndNoZone() {
        var ctx = context(EnumSet.of(COACH));

        assertThat(ctx.playerTeamIds()).isEmpty();
        assertThat(ctx.timezone()).isEmpty();
        assertThat(new AuthzContext("s", UUID.randomUUID(), TENANT, Set.of(), Set.of(), Set.of(), Optional.empty(), null, null)
                .playerTeamIds()).isEmpty();
    }

    @Test
    void formerStaffNeedAStaffRoleAndAHistoricStaffRowAndAreNotCurrentStaff() {
        UUID pastTeam = UUID.randomUUID();
        var coach = context(EnumSet.of(COACH)).withHistoricStaffTeamIds(Set.of(pastTeam));
        var assistant = context(EnumSet.of(ASSISTANT_COACH)).withHistoricStaffTeamIds(Set.of(pastTeam));
        var parent = context(EnumSet.of(PARENT)).withHistoricStaffTeamIds(Set.of(pastTeam));

        assertThat(coach.wasStaffOf(pastTeam)).isTrue();
        assertThat(assistant.wasStaffOf(pastTeam)).isTrue();
        assertThat(coach.isStaffOf(pastTeam)).as("history never grants today's access").isFalse();
        assertThat(coach.wasStaffOf(TEAM)).as("a current team is not history").isFalse();
        assertThat(parent.wasStaffOf(pastTeam)).as("staff role required").isFalse();
        assertThat(coach.historicStaffTeamIds()).containsExactly(pastTeam);
        assertThat(coach.staffTeamIds()).containsExactly(TEAM);
    }

    @Test
    void historicStaffTeamsDefaultToNoneAndAreCopied() {
        var teams = new HashSet<UUID>(Set.of(TEAM));
        var ctx = context(EnumSet.of(COACH)).withHistoricStaffTeamIds(teams);
        teams.clear();

        assertThat(context(EnumSet.of(COACH)).historicStaffTeamIds()).isEmpty();
        assertThat(new AuthzContext("s", UUID.randomUUID(), TENANT, Set.of(), Set.of(), Set.of(), Optional.empty(), null,
                null, null).historicStaffTeamIds()).isEmpty();
        assertThat(ctx.historicStaffTeamIds()).containsExactly(TEAM);
        assertThatThrownBy(() -> ctx.historicStaffTeamIds().add(TEAM)).isInstanceOf(UnsupportedOperationException.class);
    }
}
