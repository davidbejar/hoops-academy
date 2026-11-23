package com.hoopsacademy.core.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The season end of each known team (the {@code seasonEnds} read of the membership rule, ADR-0066): one query, unknown
 * ids and other tenants' teams absent.
 */
@QuarkusTest
@CoreTestResources
class TeamSeasonEndsTest {

    @Inject
    TeamRepository teams;

    @Inject
    TenantScope tenantScope;

    @Test
    void eachKnownTeamOfTheBoundTenantWithItsSeasonsLastDay() {
        String tenant = Members.newTenant();
        UUID category = RosterDb.defaultCategories(tenant).values().iterator().next();
        LocalDate pastEnd = LocalDate.parse("2026-06-30");
        LocalDate nextEnd = LocalDate.parse("2027-06-30");
        UUID past = RosterDb.team(tenant, RosterDb.season(tenant, "Past", LocalDate.parse("2025-09-01"), pastEnd, 2025),
                "Past team", category, "MIXED");
        UUID next = RosterDb.team(tenant, RosterDb.season(tenant, "Next", LocalDate.parse("2026-09-01"), nextEnd, 2026),
                "Next team", category, "MIXED");
        String other = Members.newTenant();
        UUID othersTeam = RosterDb.team(other, RosterDb.currentSeason(other), "Theirs",
                RosterDb.defaultCategories(other).values().iterator().next(), "MIXED");

        Map<TeamId, LocalDate> ends = tenantScope.runAs(TenantId.parse(tenant), () -> teams.seasonEnds(List.of(
                new TeamId(past), new TeamId(next), new TeamId(othersTeam), TeamId.random())));

        assertThat(ends).containsOnly(Map.entry(new TeamId(past), pastEnd), Map.entry(new TeamId(next), nextEnd));
    }

    @Test
    void noIdsNoQuery() {
        assertThat(tenantScope.runAs(TenantId.parse(Members.newTenant()), () -> teams.seasonEnds(List.of())))
                .isEmpty();
    }
}
