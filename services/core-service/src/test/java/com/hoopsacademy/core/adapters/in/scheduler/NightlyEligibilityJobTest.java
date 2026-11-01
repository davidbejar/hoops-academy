package com.hoopsacademy.core.adapters.in.scheduler;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.roster.EligibilitySweep;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.UUID;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class NightlyEligibilityJobTest {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");
    private static final ZoneId JAKARTA = ZoneId.of("Asia/Jakarta");

    @Inject
    EligibilitySweep sweep;

    @Inject
    NightlyEligibilityJob job;

    /** A tenant with a U12 team in a season around {@code today}; returns the tenant id. */
    private record Academy(String tenant, UUID team) {

        static Academy create(String ageRule, String zone, LocalDate today, int referenceYear) {
            String tenant = Members.newTenant();
            RosterDb.timezone(tenant, zone);
            RosterDb.settings(tenant, ageRule, null);
            UUID u12 = RosterDb.defaultCategories(tenant).get("U12");
            UUID season = RosterDb.season(tenant, "S", today.minusDays(60), today.plusDays(240), referenceYear);
            return new Academy(tenant, RosterDb.team(tenant, season, "Lions", u12, "MIXED"));
        }

        UUID assign(String name, LocalDate birthDate) {
            UUID player = RosterDb.player(tenant, name, "Test", birthDate, "MALE");
            RosterDb.assignment(tenant, team, player, null);
            return player;
        }

        long openCases() {
            return CoreDb.count(tenant, "select count(*) from core.eligibility_case where status = 'OPEN'");
        }

        long invalidAssignmentsOf(UUID player) {
            return CoreDb.count(tenant, "select count(*) from core.team_player where player_id = ? and left_on is null "
                    + "and invalidated_at is not null", player);
        }
    }

    @Test
    void theDayAfterTheTwelfthBirthdayABirthdayTenantFlagsThePlayerAndOtherTenantsAreUntouched() {
        Instant now = Instant.now();
        LocalDate today = LocalDate.ofInstant(now, MADRID);
        LocalDate twelfthBirthdayYesterday = today.minusDays(1).minusYears(12);

        Academy birthday = Academy.create("BIRTHDAY", "Europe/Madrid", today, today.getYear());
        UUID pia = birthday.assign("Pia", twelfthBirthdayYesterday);
        UUID quin = birthday.assign("Quin", today.plusDays(1).minusYears(12));
        Academy birthYear = Academy.create("BIRTH_YEAR", "Europe/Madrid", today, twelfthBirthdayYesterday.getYear() + 11);
        UUID ray = birthYear.assign("Ray", twelfthBirthdayYesterday);
        Academy suspended = Academy.create("BIRTHDAY", "Europe/Madrid", today, today.getYear());
        UUID sam = suspended.assign("Sam", twelfthBirthdayYesterday);
        CoreDb.inTenant(null, c -> CoreDb.update(c, "update core.tenant set status = 'SUSPENDED' where id = ?::uuid",
                suspended.tenant()));

        EligibilitySweep.Summary summary = sweep.sweepActiveTenants(now);

        assertThat(summary.tenants()).isGreaterThanOrEqualTo(2);
        assertThat(birthday.openCases()).isEqualTo(1);
        assertThat(birthday.invalidAssignmentsOf(pia)).isEqualTo(1);
        assertThat(RosterDb.text(birthday.tenant(), "select invalid_reason from core.team_player where player_id = ?", pia))
                .isEqualTo("CATEGORY_TOO_LOW");
        assertThat(RosterDb.playerStatus(birthday.tenant(), pia)).isEqualTo("ORPHAN");
        assertThat(birthday.invalidAssignmentsOf(quin)).isZero();
        assertThat(RosterDb.playerStatus(birthday.tenant(), quin)).isEqualTo("ACTIVE");

        assertThat(birthYear.openCases()).isZero();
        assertThat(birthYear.invalidAssignmentsOf(ray)).isZero();
        assertThat(RosterDb.playerStatus(birthYear.tenant(), ray)).isEqualTo("ACTIVE");
        assertThat(suspended.openCases()).isZero();
        assertThat(RosterDb.playerStatus(suspended.tenant(), sam)).isEqualTo("ACTIVE");

        sweep.sweepActiveTenants(now);
        job.run();
        assertThat(birthday.openCases()).as("idempotent").isEqualTo(1);
        assertThat(CoreDb.count(birthday.tenant(), "select count(*) from core.eligibility_case")).isEqualTo(1);
    }

    @Test
    void localMidnightDecidesTheBirthday() {
        LocalDate madridDay = LocalDate.now(MADRID).plusDays(5);
        Instant eveningInMadrid = madridDay.atTime(LocalTime.of(20, 0)).atZone(MADRID).toInstant();
        LocalDate jakartaDay = LocalDate.ofInstant(eveningInMadrid, JAKARTA);
        assertThat(jakartaDay).isEqualTo(madridDay.plusDays(1));
        LocalDate born = jakartaDay.minusYears(12);

        Academy jakarta = Academy.create("BIRTHDAY", "Asia/Jakarta", madridDay, madridDay.getYear());
        UUID inJakarta = jakarta.assign("Jaya", born);
        Academy madrid = Academy.create("BIRTHDAY", "Europe/Madrid", madridDay, madridDay.getYear());
        UUID inMadrid = madrid.assign("Mateo", born);

        sweep.sweepActiveTenants(eveningInMadrid);

        assertThat(jakarta.invalidAssignmentsOf(inJakarta)).as("already the birthday in Jakarta").isEqualTo(1);
        assertThat(madrid.invalidAssignmentsOf(inMadrid)).as("still the day before in Madrid").isZero();
    }

    @Test
    void aBrokenTenantIsSkippedWithoutStoppingTheSweep() {
        UUID broken = UUID.randomUUID();
        CoreDb.inTenant(broken.toString(), c -> {
            CoreDb.insertTenantRow(c, broken, "ACTIVE");
            return null;
        });
        Instant now = Instant.now();
        LocalDate today = LocalDate.ofInstant(now, MADRID);
        Academy academy = Academy.create("BIRTHDAY", "Europe/Madrid", today, today.getYear());
        UUID pia = academy.assign("Pia", today.minusDays(1).minusYears(12));

        EligibilitySweep.Summary summary = sweep.sweepActiveTenants(now);

        assertThat(summary.failedTenants()).as("the tenant without settings").isGreaterThanOrEqualTo(1);
        assertThat(academy.invalidAssignmentsOf(pia)).isEqualTo(1);
    }

    @Test
    void underBirthYearNothingChangesBetweenRollovers() {
        LocalDate today = LocalDate.now(MADRID);
        Academy academy = Academy.create("BIRTH_YEAR", "Europe/Madrid", today, today.getYear());
        UUID eleven = academy.assign("Eli", LocalDate.of(today.getYear() - 11, 12, 31));
        sweep.sweepActiveTenants(Instant.now().plusSeconds(86_400L * 200));
        assertThat(academy.invalidAssignmentsOf(eleven)).isZero();
        assertThat(academy.openCases()).isZero();
    }
}
