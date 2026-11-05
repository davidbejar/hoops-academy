package com.hoopsacademy.game.application;

import static com.hoopsacademy.game.domain.events.Script.player;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.PlayerVisibility;
import com.hoopsacademy.game.domain.TeamId;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The single rule behind the box-score lines and the event feed (ADR-0021 §3, ADR-0028): ADMIN and staff of the
 * match's team see every player; anybody else sees linked players (PARENT) and the own player (PLAYER) only.
 */
class StatVisibilityTest {

    static final TenantId TENANT = TenantId.parse("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa");
    static final TeamId TEAM = TeamId.of(UUID.fromString("11111111-0000-4000-8000-000000000011"));
    static final UUID OTHER_TEAM = UUID.fromString("11111111-0000-4000-8000-000000000012");
    static final PlayerId CHILD = player(1), OTHER = player(2);

    static AuthzContext caller(Set<TenantRole> roles, Set<UUID> staffTeams, Set<UUID> linked, UUID ownPlayer) {
        return new AuthzContext("sub", UUID.randomUUID(), TENANT, roles, staffTeams, linked, Optional.ofNullable(ownPlayer));
    }

    static PlayerVisibility of(AuthzContext caller) {
        return StatVisibility.forTeam(caller, TEAM);
    }

    @Test
    void adminAndStaffOfTheTeamSeeEveryPlayer() {
        assertThat(of(caller(Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null)).seesAll()).isTrue();
        assertThat(of(caller(Set.of(TenantRole.COACH), Set.of(TEAM.value()), Set.of(), null)).seesAll()).isTrue();
        assertThat(of(caller(Set.of(TenantRole.ASSISTANT_COACH), Set.of(TEAM.value()), Set.of(), null)).seesAll()).isTrue();
        assertThat(of(caller(Set.of(TenantRole.ADMIN, TenantRole.PLAYER), Set.of(), Set.of(), OTHER.value())).seesAll())
                .isTrue();
    }

    @Test
    void aParentSeesLinkedPlayersOnly() {
        PlayerVisibility parent = of(caller(Set.of(TenantRole.PARENT), Set.of(), Set.of(CHILD.value()), null));

        assertThat(parent.seesAll()).isFalse();
        assertThat(parent.sees(CHILD)).isTrue();
        assertThat(parent.sees(OTHER)).isFalse();
    }

    @Test
    void aPlayerSeesThemselvesOnly() {
        PlayerVisibility self = of(caller(Set.of(TenantRole.PLAYER), Set.of(), Set.of(), CHILD.value()));

        assertThat(self.seesAll()).isFalse();
        assertThat(self.sees(CHILD)).isTrue();
        assertThat(self.sees(OTHER)).isFalse();
    }

    @Test
    void staffOfAnotherTeamIsTreatedLikeAnyOtherMember() {
        assertThat(of(caller(Set.of(TenantRole.COACH), Set.of(OTHER_TEAM), Set.of(), null)))
                .isEqualTo(PlayerVisibility.only(Set.of()));
        PlayerVisibility coachAndParent = of(caller(Set.of(TenantRole.COACH, TenantRole.PARENT), Set.of(OTHER_TEAM),
                Set.of(CHILD.value()), null));
        assertThat(coachAndParent.seesAll()).isFalse();
        assertThat(coachAndParent.sees(CHILD)).isTrue();
    }

    @Test
    void relationsWithoutTheMatchingRoleGrantNothing() {
        assertThat(of(caller(Set.of(), Set.of(TEAM.value()), Set.of(CHILD.value()), OTHER.value())))
                .isEqualTo(PlayerVisibility.only(Set.of()));
    }
}
