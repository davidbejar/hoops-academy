package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.domain.shared.Patch;
import org.junit.jupiter.api.Test;

class TeamTest {

    private final Team team = new Team(TeamId.random(), SeasonId.random(), " Lions ", " ", AgeCategoryId.random(),
            GenderPolicy.MIXED);

    @Test
    void normalisesNameAndBlankAlias() {
        assertThat(team.name()).isEqualTo("Lions");
        assertThat(team.alias()).isNull();
        assertThat(new Team(TeamId.random(), SeasonId.random(), "A", " Cubs ", AgeCategoryId.random(), GenderPolicy.MALE)
                .alias()).isEqualTo("Cubs");
        assertThatThrownBy(() -> new Team(TeamId.random(), SeasonId.random(), "A", "x".repeat(41), AgeCategoryId.random(),
                GenderPolicy.MALE)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new Team(TeamId.random(), SeasonId.random(), "", null, AgeCategoryId.random(),
                GenderPolicy.MALE)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new Team(TeamId.random(), SeasonId.random(), "A", null, null, GenderPolicy.MALE))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new Team(TeamId.random(), SeasonId.random(), "A", null, AgeCategoryId.random(), null))
                .isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void changesAndClones() {
        AgeCategoryId other = AgeCategoryId.random();
        Team changed = team.apply(new TeamChanges(Patch.of("Tigers"), Patch.of("T"), Patch.of(other), Patch.of(GenderPolicy.FEMALE)));
        assertThat(changed).isEqualTo(new Team(team.id(), team.season(), "Tigers", "T", other, GenderPolicy.FEMALE));
        assertThat(new TeamChanges(Patch.absent(), Patch.of(null), Patch.absent(), Patch.absent()).changesEligibility()).isFalse();
        assertThat(new TeamChanges(Patch.absent(), Patch.absent(), Patch.of(other), Patch.absent()).changesEligibility()).isTrue();
        assertThat(new TeamChanges(Patch.absent(), Patch.absent(), Patch.absent(), Patch.of(GenderPolicy.MALE)).changesEligibility()).isTrue();

        SeasonId next = SeasonId.random();
        Team clone = team.cloneInto(next);
        assertThat(clone.id()).isNotEqualTo(team.id());
        assertThat(clone.season()).isEqualTo(next);
        assertThat(clone.name()).isEqualTo(team.name());
        assertThat(clone.category()).isEqualTo(team.category());
        assertThat(clone.genderPolicy()).isEqualTo(team.genderPolicy());
    }

    @Test
    void staffRolesMapToTenantRoles() {
        assertThat(StaffRole.COACH.tenantRole()).isEqualTo(TenantRole.COACH);
        assertThat(StaffRole.ASSISTANT_COACH.tenantRole()).isEqualTo(TenantRole.ASSISTANT_COACH);
    }
}
