package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.tenancy.TenantRole;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Roster fixtures written as the migrator (see {@link CoreDb}). Dates are relative to the real "today" so the suites
 * keep their meaning as time passes: {@link #currentSeason} contains today and uses today's year as reference year.
 */
public final class RosterDb {

    public static final LocalDate TODAY = LocalDate.now(java.time.ZoneId.of("Europe/Madrid"));
    public static final int YEAR = TODAY.getYear();

    private RosterDb() {}

    /** The default ladder U8 … SENIOR (tenants created by {@link CoreDb#tenant} have no categories). */
    public static Map<String, UUID> defaultCategories(String tenant) {
        Map<String, UUID> ids = new LinkedHashMap<>();
        Object[][] ladder = {{"U8", 7}, {"U10", 9}, {"U12", 11}, {"U14", 13}, {"U16", 15}, {"U18", 17}, {"SENIOR", null}};
        CoreDb.inTenant(tenant, c -> {
            for (int rank = 0; rank < ladder.length; rank++) {
                UUID id = UUID.randomUUID();
                CoreDb.update(c, "insert into core.age_category (id, tenant_id, code, name, max_age, sort_rank) "
                        + "values (?, ?::uuid, ?, ?, ?, ?)", id, tenant, ladder[rank][0], ladder[rank][0], ladder[rank][1], rank);
                ids.put((String) ladder[rank][0], id);
            }
            return null;
        });
        return ids;
    }

    public static UUID season(String tenant, String name, LocalDate from, LocalDate to, int referenceYear) {
        return CoreDb.inTenant(tenant, c -> {
            UUID id = UUID.randomUUID();
            CoreDb.update(c, "insert into core.season (id, tenant_id, name, start_date, end_date, reference_year) "
                    + "values (?, ?::uuid, ?, ?, ?, ?)", id, tenant, name, from, to, referenceYear);
            return id;
        });
    }

    /** A season around today (60 days back, 240 ahead), reference year = this year. */
    public static UUID currentSeason(String tenant) {
        return season(tenant, "Current", TODAY.minusDays(60), TODAY.plusDays(240), YEAR);
    }

    public static UUID team(String tenant, UUID season, String name, UUID category, String genderPolicy) {
        return CoreDb.inTenant(tenant, c -> {
            UUID id = UUID.randomUUID();
            CoreDb.update(c, "insert into core.team (id, tenant_id, season_id, name, age_category_id, gender_policy) "
                    + "values (?, ?::uuid, ?, ?, ?, ?)", id, tenant, season, name, category, genderPolicy);
            return id;
        });
    }

    public static void staff(String tenant, UUID team, UUID person, String role) {
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "insert into core.team_staff (tenant_id, team_id, person_id, role, since) "
                + "values (?::uuid, ?, ?, ?, ?)", tenant, team, person, role, TODAY));
    }

    /** A person with the PLAYER role and an ACTIVE player record; returns the player id. */
    public static UUID player(String tenant, String given, String family, LocalDate birthDate, String gender) {
        UUID person = CoreDb.person(tenant, null, given, family, null, birthDate, gender, TenantRole.PLAYER);
        return CoreDb.player(tenant, person);
    }

    /** A player whose age is {@code age} under BIRTH_YEAR in {@link #YEAR} (born mid-year). */
    public static UUID playerAged(String tenant, String given, int age, String gender) {
        return player(tenant, given, "Test", LocalDate.of(YEAR - age, 6, 15), gender);
    }

    public static UUID assignment(String tenant, UUID team, UUID player, String jersey) {
        return CoreDb.inTenant(tenant, c -> {
            UUID id = UUID.randomUUID();
            CoreDb.update(c, "insert into core.team_player (id, tenant_id, team_id, player_id, jersey_number, joined_on) "
                    + "values (?, ?::uuid, ?, ?, ?, ?)", id, tenant, team, player, jersey, TODAY.minusDays(30));
            return id;
        });
    }

    /** Invalidates {@code assignment} for {@code reason} and opens its case, as the evaluator would; returns the case id. */
    public static UUID openCase(String tenant, UUID assignment, String reason) {
        return CoreDb.inTenant(tenant, c -> {
            CoreDb.update(c, "update core.team_player set invalidated_at = now(), invalid_reason = ? where id = ?",
                    reason, assignment);
            UUID id = UUID.randomUUID();
            CoreDb.update(c, "insert into core.eligibility_case (id, tenant_id, player_id, team_player_id, reason) "
                    + "select ?, tenant_id, player_id, id, ? from core.team_player where id = ?", id, reason, assignment);
            return id;
        });
    }

    public static void settings(String tenant, String ageRule, Integer maxPlayUpLevels) {
        CoreDb.inTenant(tenant, c -> CoreDb.update(c,
                "update core.tenant_settings set age_rule = ?, max_play_up_levels = ? where tenant_id = ?::uuid",
                ageRule, maxPlayUpLevels, tenant));
    }

    public static void timezone(String tenant, String zone) {
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.tenant set timezone = ? where id = ?::uuid", zone, tenant));
    }

    /** The person row (an ADMIN) behind {@link Members#callerPersonId}, needed where the caller is referenced. */
    public static UUID callerPerson(String tenant) {
        UUID id = Members.callerPersonId(tenant);
        CoreDb.inTenant(tenant, c -> {
            CoreDb.update(c, "insert into core.person (id, tenant_id, given_name, family_name) "
                    + "values (?, ?::uuid, 'Cal', 'Ler') on conflict do nothing", id, tenant);
            return CoreDb.update(c, "insert into core.membership_role (tenant_id, person_id, role) "
                    + "values (?::uuid, ?, 'ADMIN') on conflict do nothing", tenant, id);
        });
        return id;
    }

    public static String playerStatus(String tenant, UUID player) {
        return text(tenant, "select status from core.player where id = ?", player);
    }

    public static String text(String tenant, String sql, Object... params) {
        return CoreDb.inTenant(tenant, c -> {
            try (PreparedStatement statement = c.prepareStatement(sql)) {
                CoreDb.bind(statement, params);
                try (ResultSet rs = statement.executeQuery()) {
                    return rs.next() ? rs.getString(1) : null;
                }
            }
        });
    }
}
