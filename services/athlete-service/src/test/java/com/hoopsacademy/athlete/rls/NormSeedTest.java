package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.domain.BandResolver;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.NormBand;
import com.hoopsacademy.athlete.domain.NormId;
import com.hoopsacademy.athlete.domain.PhysicalTestNorm;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** The repeatable norm seed: six test types, ages 8-18 by gender in five ordered bands, a source per block. */
@QuarkusTest
@Tag("rls")
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class NormSeedTest {

    private static final Map<String, Boolean> TYPES = Map.of("COOPER_12MIN", true, "SPRINT_20M", false, "VERTICAL_JUMP", true,
            "AGILITY_T_TEST", false, "SIT_AND_REACH", true, "BEEP_TEST", true);
    private static final Map<String, String> UNITS = Map.of("COOPER_12MIN", "m", "SPRINT_20M", "s", "VERTICAL_JUMP", "cm",
            "AGILITY_T_TEST", "s", "SIT_AND_REACH", "cm", "BEEP_TEST", "level");

    record SeedNorm(String code, boolean higherIsBetter, PhysicalTestNorm norm, String source) {}

    @Test
    void sixGlobalTestTypesWithUnitAndDirection() throws Exception {
        Map<String, String> found = new LinkedHashMap<>();
        try (Connection app = app(); Statement st = app.createStatement();
                ResultSet rs = st.executeQuery("select code, unit, higher_is_better from athlete.physical_test_type "
                        + "where owner_tenant_id is null and code = any (array['COOPER_12MIN','SPRINT_20M','VERTICAL_JUMP',"
                        + "'AGILITY_T_TEST','SIT_AND_REACH','BEEP_TEST']) order by code")) {
            while (rs.next()) {
                found.put(rs.getString(1), rs.getString(2) + "|" + rs.getBoolean(3));
            }
        }

        assertThat(found).hasSize(6);
        TYPES.forEach((code, higher) -> assertThat(found.get(code)).isEqualTo(UNITS.get(code) + "|" + higher));
    }

    @Test
    void everyTestGenderAndAgeFrom8To18HasFiveBandsInOrderWithoutGaps() throws Exception {
        List<SeedNorm> all = load();

        for (String code : TYPES.keySet()) {
            for (Gender gender : Gender.values()) {
                for (int age = 8; age <= 18; age++) {
                    final int a = age;
                    List<PhysicalTestNorm> atAge = all.stream().filter(n -> n.code().equals(code))
                            .map(SeedNorm::norm).filter(n -> n.gender() == gender && n.covers(gender, a)).toList();
                    String where = code + " " + gender + " age " + age;
                    EnumMap<NormBand, Long> perBand = atAge.stream()
                            .collect(Collectors.groupingBy(PhysicalTestNorm::band, () -> new EnumMap<>(NormBand.class), Collectors.counting()));
                    assertThat(perBand.keySet()).as(where).containsExactlyInAnyOrder(NormBand.values());
                    assertThat(perBand.values()).as(where).containsOnly(1L);
                    assertThat(BandResolver.bandsAreOrdered(atAge, TYPES.get(code))).as(where + " ordered").isTrue();
                    assertThat(contiguous(atAge, TYPES.get(code))).as(where + " contiguous").isTrue();
                }
            }
        }
    }

    @Test
    void everyRowCitesASourceAndPlaceholdersAreFlaggedPending() throws Exception {
        List<SeedNorm> all = load();

        assertThat(all).isNotEmpty().allSatisfy(n -> {
            assertThat(n.source()).as(n.code() + " source").isNotBlank();
            boolean placeholder = n.source().toLowerCase().contains("placeholder");
            assertThat(n.norm().referencePending()).as(n.code() + " " + n.source()).isEqualTo(placeholder);
        });
        assertThat(all).anySatisfy(n -> assertThat(n.norm().referencePending()).isFalse());
        assertThat(all).anySatisfy(n -> assertThat(n.norm().referencePending()).isTrue());
    }

    @Test
    void theSourcedCooperBlocksAreTheCooperTableForTeenagers() throws Exception {
        List<SeedNorm> cooper = load().stream().filter(n -> n.code().equals("COOPER_12MIN") && !n.norm().referencePending()).toList();

        assertThat(cooper).isNotEmpty().allSatisfy(n -> {
            assertThat(n.source()).contains("Cooper").contains("1968");
            assertThat(n.norm().minAge()).isGreaterThanOrEqualTo(13);
        });
        // 14 year old boys: 2400-2700 m is above average, from 2700 m excellent (Cooper 1968, 13-14 years)
        var boys14 = cooper.stream().map(SeedNorm::norm).toList();
        var resolved = BandResolver.resolve(boys14, java.util.Optional.of(Gender.MALE), java.util.OptionalInt.of(14),
                new java.math.BigDecimal("2500"));
        assertThat(resolved.expectedBand()).contains(NormBand.ABOVE_AVERAGE);
        assertThat(resolved.referencePending()).isFalse();
    }

    @Test
    void theBeepTestFollowsTheFitBackEuropeanTableAtEveryAge() throws Exception {
        List<SeedNorm> beep = rows("BEEP_TEST");

        assertThat(beep).hasSize(2 * 11 * 5).allSatisfy(n -> {
            assertThat(n.norm().referencePending()).isFalse();
            assertThat(n.source()).contains("Ortega").contains("2023").contains("Table 1");
        });
        // Ortega et al. 2023, Table 1: boys 18.0-18.9 P80 = 8.6 stages, girls 8.0-8.9 P20 = 1.5 stages
        assertThat(band(beep, Gender.MALE, 18, "8.6")).isEqualTo(NormBand.EXCELLENT);
        assertThat(band(beep, Gender.MALE, 18, "8.5")).isEqualTo(NormBand.ABOVE_AVERAGE);
        assertThat(band(beep, Gender.FEMALE, 8, "1.4")).isEqualTo(NormBand.POOR);
        assertThat(band(beep, Gender.FEMALE, 8, "1.5")).isEqualTo(NormBand.BELOW_AVERAGE);
    }

    @Test
    void theSitAndReachFollowsCatleyAndTomkinsonFrom9To17() throws Exception {
        List<SeedNorm> sit = rows("SIT_AND_REACH");

        assertThat(sit).allSatisfy(n -> {
            boolean inSource = n.norm().minAge() >= 9 && n.norm().maxAge() <= 17;
            assertThat(n.norm().referencePending()).as(n.norm().minAge() + " pending").isEqualTo(!inSource);
            assertThat(n.source()).contains("Catley").contains("Table 10");
        });
        // Catley & Tomkinson 2013, Table 10: girls 14 P20 = 23.1 cm, boys 17 P80 = 33.0 cm
        assertThat(band(sit, Gender.FEMALE, 14, "23.0")).isEqualTo(NormBand.POOR);
        assertThat(band(sit, Gender.FEMALE, 14, "23.1")).isEqualTo(NormBand.BELOW_AVERAGE);
        assertThat(band(sit, Gender.MALE, 17, "33.0")).isEqualTo(NormBand.EXCELLENT);
    }

    @Test
    void theSprintBandsComeFromThePublishedLmsFrom8To17() throws Exception {
        List<SeedNorm> sprint = rows("SPRINT_20M");

        assertThat(sprint).allSatisfy(n -> {
            assertThat(n.norm().referencePending()).as(n.norm().minAge() + " pending").isEqualTo(n.norm().minAge() == 18);
            assertThat(n.source()).contains("Cossio-Bolanos").contains("LMS");
        });
        // Cossio-Bolanos et al. 2026, Table 4, boys 12: L -2.382, M 3.997, S 0.110 -> P20 3.68 s, P80 4.44 s
        assertThat(band(sprint, Gender.MALE, 12, "3.67")).isEqualTo(NormBand.EXCELLENT);
        assertThat(band(sprint, Gender.MALE, 12, "3.997")).isEqualTo(NormBand.AVERAGE);
        assertThat(band(sprint, Gender.MALE, 12, "4.44")).isEqualTo(NormBand.POOR);
    }

    @Test
    void theTTestAndVerticalJumpAreCitedOnlyAt14And15() throws Exception {
        for (String code : List.of("AGILITY_T_TEST", "VERTICAL_JUMP")) {
            assertThat(rows(code)).allSatisfy(n -> {
                boolean florence = n.norm().minAge() >= 14 && n.norm().maxAge() <= 15;
                assertThat(n.norm().referencePending()).as(code + " " + n.norm().minAge()).isEqualTo(!florence);
                assertThat(n.source().contains("Mascherini")).as(code + " " + n.norm().minAge()).isEqualTo(florence);
            });
        }
        // Mascherini et al. 2022, Table 2 (boys, first class): T-agility P10 10.2, P25 10.7 -> P20 = 10.53 s
        assertThat(band(rows("AGILITY_T_TEST"), Gender.MALE, 14, "10.52")).isEqualTo(NormBand.EXCELLENT);
        assertThat(band(rows("AGILITY_T_TEST"), Gender.MALE, 14, "10.53")).isEqualTo(NormBand.ABOVE_AVERAGE);
    }

    @Test
    void placeholderRowsAreOnlyTheDocumentedGaps() throws Exception {
        Map<String, Long> pending = load().stream().filter(n -> n.norm().referencePending())
                .collect(Collectors.groupingBy(SeedNorm::code, Collectors.counting()));

        // docs/domain/norms.md, "Per test: sources and status"
        assertThat(pending).containsExactlyInAnyOrderEntriesOf(Map.of("COOPER_12MIN", 50L, "SIT_AND_REACH", 20L,
                "SPRINT_20M", 10L, "VERTICAL_JUMP", 90L, "AGILITY_T_TEST", 90L));
    }

    @Test
    void runningTheSeedAgainChangesNothingAndForceIsRestored() throws Exception {
        String before = fingerprint();

        runSeed();
        runSeed();

        assertThat(fingerprint()).isEqualTo(before);
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator(); Statement st = migrator.createStatement();
                ResultSet rs = st.executeQuery("select count(*) from pg_class where oid in ('athlete.physical_test_type'::regclass, "
                        + "'athlete.physical_test_norm'::regclass) and relforcerowsecurity")) {
            rs.next();
            assertThat(rs.getInt(1)).as("FORCE restored on both tables").isEqualTo(2);
        }
    }

    private static boolean contiguous(List<PhysicalTestNorm> atAge, boolean higherIsBetter) {
        List<PhysicalTestNorm> ordered = new ArrayList<>(atAge);
        ordered.sort(java.util.Comparator.comparing(PhysicalTestNorm::band));
        if (!higherIsBetter) {
            java.util.Collections.reverse(ordered);
        }
        for (int i = 0; i + 1 < ordered.size(); i++) {
            if (!ordered.get(i).maxValue().equals(ordered.get(i + 1).minValue())) {
                return false;
            }
        }
        return ordered.get(0).minValue().isEmpty() && ordered.get(ordered.size() - 1).maxValue().isEmpty();
    }

    private static List<SeedNorm> rows(String code) throws SQLException {
        return load().stream().filter(n -> n.code().equals(code)).toList();
    }

    private static NormBand band(List<SeedNorm> rows, Gender gender, int age, String value) {
        return BandResolver.resolve(rows.stream().map(SeedNorm::norm).toList(), java.util.Optional.of(gender),
                java.util.OptionalInt.of(age), new java.math.BigDecimal(value)).expectedBand().orElseThrow();
    }

    private static List<SeedNorm> load() throws SQLException {
        List<SeedNorm> rows = new ArrayList<>();
        try (Connection app = app(); Statement st = app.createStatement();
                ResultSet rs = st.executeQuery("select t.code, t.higher_is_better, n.id, n.test_type_id, n.gender, n.min_age, n.max_age, "
                        + "n.band, n.min_value, n.max_value, n.reference_pending, n.source "
                        + "from athlete.physical_test_norm n join athlete.physical_test_type t on t.id = n.test_type_id "
                        + "where n.owner_tenant_id is null and t.owner_tenant_id is null and t.code = any (array['COOPER_12MIN',"
                        + "'SPRINT_20M','VERTICAL_JUMP','AGILITY_T_TEST','SIT_AND_REACH','BEEP_TEST'])")) {
            while (rs.next()) {
                PhysicalTestNorm norm = PhysicalTestNorm.of(new NormId(rs.getObject(3, UUID.class)),
                        new TestTypeId(rs.getObject(4, UUID.class)), Gender.valueOf(rs.getString(5)), rs.getInt(6), rs.getInt(7),
                        NormBand.valueOf(rs.getString(8)), rs.getBigDecimal(9), rs.getBigDecimal(10), rs.getBoolean(11),
                        rs.getString(12), true);
                rows.add(new SeedNorm(rs.getString(1), rs.getBoolean(2), norm, rs.getString(12)));
            }
        }
        return rows;
    }

    private static String fingerprint() throws SQLException {
        try (Connection app = app(); Statement st = app.createStatement();
                ResultSet rs = st.executeQuery("select count(*) || '|' || md5(string_agg(n.id::text || n.band || coalesce(n.min_value::text,'') "
                        + "|| coalesce(n.max_value::text,'') || n.reference_pending || n.source, ',' order by n.id)) "
                        + "from athlete.physical_test_norm n where n.owner_tenant_id is null "
                        + "and n.test_type_id in (select id from athlete.physical_test_type where code = any (array['COOPER_12MIN',"
                        + "'SPRINT_20M','VERTICAL_JUMP','AGILITY_T_TEST','SIT_AND_REACH','BEEP_TEST']))")) {
            rs.next();
            return rs.getString(1);
        }
    }

    private static Connection app() throws SQLException {
        Connection app = RlsTestDatabase.fromConfig().openAsApp();
        app.setAutoCommit(false);
        try (Statement st = app.createStatement()) {
            st.execute("select set_config('app.tenant_id', '00000000-0000-4000-8000-00000000feed', true)");
        }
        return app;
    }

    private static void runSeed() throws IOException, SQLException {
        String sql;
        try (var in = NormSeedTest.class.getResourceAsStream("/db/migration/R__physical_test_norms.sql")) {
            sql = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator()) {
            migrator.setAutoCommit(false);
            try (Statement st = migrator.createStatement()) {
                st.execute(sql);
            }
            migrator.commit();
        }
    }
}
