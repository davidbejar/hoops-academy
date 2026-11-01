package com.hoopsacademy.core.domain.approvals;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.EnumSet;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

class ApprovalPolicyTest {

    @ParameterizedTest
    @EnumSource(ApprovalAction.class)
    void anAdminActsDirectly(ApprovalAction action) {
        assertThat(ApprovalPolicy.requiresApproval(Set.of(TenantRole.ADMIN), action)).isFalse();
    }

    @ParameterizedTest
    @EnumSource(ApprovalAction.class)
    void adminWinsOverCoachWhenBothAreHeld(ApprovalAction action) {
        assertThat(ApprovalPolicy.requiresApproval(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), action)).isFalse();
    }

    @ParameterizedTest
    @EnumSource(ApprovalAction.class)
    void aCoachNeedsApproval(ApprovalAction action) {
        assertThat(ApprovalPolicy.requiresApproval(Set.of(TenantRole.COACH), action)).isTrue();
        assertThat(ApprovalPolicy.requiresApproval(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), action)).isTrue();
    }

    @ParameterizedTest
    @EnumSource(value = TenantRole.class, names = {"ASSISTANT_COACH", "PARENT", "PLAYER"})
    void everyoneElseIsForbidden(TenantRole role) {
        assertThatThrownBy(() -> ApprovalPolicy.requiresApproval(Set.of(role), ApprovalAction.ADD_PLAYER))
                .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> ApprovalPolicy.requiresApproval(Set.of(), ApprovalAction.WITHDRAW_PLAYER))
                .isInstanceOf(AccessDeniedException.class);
    }
}
