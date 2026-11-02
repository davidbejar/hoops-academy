package com.hoopsacademy.core.domain.membership;

import static com.hoopsacademy.common.tenancy.TenantRole.ADMIN;
import static com.hoopsacademy.common.tenancy.TenantRole.COACH;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.ConflictException;
import java.util.Set;
import org.junit.jupiter.api.Test;

class LastAdminRuleTest {

    @Test
    void theOnlyActiveAdminCannotLoseTheRoleOrBeDeactivated() {
        assertThatThrownBy(() -> LastAdminRule.checkRoleChange(Set.of(ADMIN), Set.of(COACH), 1))
                .isInstanceOf(ConflictException.class)
                .hasMessage("An academy needs at least one active administrator: add another administrator first")
                .extracting(e -> ((ConflictException) e).code()).isEqualTo("LAST_ADMIN");
        assertThatThrownBy(() -> LastAdminRule.checkDeactivation(Set.of(ADMIN, COACH), 1))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void otherChangesAreFine() {
        assertThatCode(() -> LastAdminRule.checkRoleChange(Set.of(ADMIN), Set.of(COACH), 2)).doesNotThrowAnyException();
        assertThatCode(() -> LastAdminRule.checkRoleChange(Set.of(ADMIN), Set.of(ADMIN, COACH), 1))
                .doesNotThrowAnyException();
        assertThatCode(() -> LastAdminRule.checkRoleChange(Set.of(COACH), Set.of(COACH), 0)).doesNotThrowAnyException();
        assertThatCode(() -> LastAdminRule.checkDeactivation(Set.of(COACH), 1)).doesNotThrowAnyException();
        assertThatCode(() -> LastAdminRule.checkDeactivation(Set.of(ADMIN), 2)).doesNotThrowAnyException();
    }
}
