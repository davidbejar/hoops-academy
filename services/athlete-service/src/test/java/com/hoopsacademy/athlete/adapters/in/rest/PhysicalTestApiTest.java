package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class PhysicalTestApiTest {

    static final String TENANT = "68000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "68000000-0000-4000-8000-000000000002";
    static final String TEAM = "68000000-0000-4000-8000-0000000000a1";
    /** Girl born 2012-05-01. */
    static final String GIRL = "68000000-0000-4000-8000-0000000000b1";
    /** Boy born 2010-01-15. */
    static final String BOY = "68000000-0000-4000-8000-0000000000b2";
    /** Core knows the player but not the birth date. */
    static final String NO_BIRTH = "68000000-0000-4000-8000-0000000000b3";
    static final String NO_GENDER = "68000000-0000-4000-8000-0000000000b4";
    static final String TYPES = "/api/athlete/physical-test-types";
    static final String RESULTS = "/api/athlete/physical-test-results";
    static final String NORMS = "/api/athlete/physical-test-norms";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        stubPlayers(TENANT);
        core.roster(TENANT, TEAM, GIRL, BOY, NO_BIRTH, NO_GENDER);
        member(TENANT, TenantRole.ADMIN);
    }

    private void stubPlayers(String tenant) {
        core.knownPlayerData(tenant, new String[] {GIRL, "2012-05-01", "FEMALE"}, new String[] {BOY, "2010-01-15", "MALE"},
                new String[] {NO_BIRTH, null, "MALE"}, new String[] {NO_GENDER, "2011-03-03", null});
    }

    private String typeId(String code) {
        List<Map<String, Object>> types = api(TENANT).get(TYPES).then().statusCode(200).extract().path("findAll { it.code == '" + code + "' }");
        return (String) types.get(0).get("id");
    }

    private Map<String, Object> result(String player, String type, String on, Object value) {
        Map<String, Object> body = new HashMap<>();
        body.put("playerId", player);
        body.put("testTypeId", type);
        body.put("measuredOn", on);
        body.put("value", value);
        return body;
    }

    private Map<String, Object> norm(String type, String gender, int minAge, int maxAge, String band, Double min, Double max, String source) {
        Map<String, Object> body = new HashMap<>();
        body.put("testTypeId", type);
        body.put("gender", gender);
        body.put("minAge", minAge);
        body.put("maxAge", maxAge);
        body.put("band", band);
        body.put("minValue", min);
        body.put("maxValue", max);
        body.put("source", source);
        return body;
    }

    // ------------------------------------------------------------------ test types
    @Test
    void everyMemberListsTheSixGlobalTypes() {
        for (Set<TenantRole> roles : List.of(Set.of(TenantRole.PARENT), Set.of(TenantRole.PLAYER), Set.of(TenantRole.COACH))) {
            member(TENANT, roles, Set.of(), Set.of(), null);
            api(TENANT).get(TYPES).then().statusCode(200).body("findAll { it.global }.code",
                    hasItems("COOPER_12MIN", "SPRINT_20M", "VERTICAL_JUMP", "AGILITY_T_TEST", "SIT_AND_REACH", "BEEP_TEST"));
        }
        member(TENANT, TenantRole.ADMIN);
        api(TENANT).get(TYPES).then().body("find { it.code == 'SPRINT_20M' }.higherIsBetter", equalTo(false))
                .body("find { it.code == 'SPRINT_20M' }.unit", equalTo("s"));
    }

    @Test
    void anAdminDefinesAndChangesCustomTypesButNotGlobalOnes() {
        String id = api(TENANT).body(Map.of("code", "SHUTTLE_5X10", "name", "5x10 shuttle", "unit", "s", "higherIsBetter", false))
                .post(TYPES).then().statusCode(201).body("global", equalTo(false)).body("code", equalTo("SHUTTLE_5X10")).extract().path("id");

        api(TENANT).get(TYPES + "/" + id).then().statusCode(200).body("name", equalTo("5x10 shuttle"));
        api(TENANT).body(Map.of("name", "Shuttle 5x10", "higherIsBetter", true)).patch(TYPES + "/" + id).then().statusCode(200)
                .body("name", equalTo("Shuttle 5x10")).body("higherIsBetter", equalTo(true)).body("unit", equalTo("s"));

        String global = typeId("COOPER_12MIN");
        lenient(TENANT).body(Map.of("name", "Hacked")).patch(TYPES + "/" + global).then().statusCode(403)
                .body("code", equalTo("TEST_TYPE_IS_GLOBAL"));
        lenient(TENANT).body(Map.of("code", "COOPER_12MIN", "name", "Mine", "unit", "m", "higherIsBetter", true)).post(TYPES)
                .then().statusCode(409);
        lenient(TENANT).body(Map.of("code", "SHUTTLE_5X10", "name", "dup", "unit", "s", "higherIsBetter", true)).post(TYPES)
                .then().statusCode(409);
        lenient(TENANT).body(Map.of("code", "bad code", "name", "x", "unit", "s", "higherIsBetter", true)).post(TYPES).then().statusCode(400);
        api(TENANT).get(TYPES + "/" + UUID.randomUUID()).then().statusCode(404);
    }

    @Test
    void onlyAdminsWriteTypesAndTenantsDoNotSeeEachOthersCustomTypes() {
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);
        lenient(TENANT).body(Map.of("code", "COACH_MADE", "name", "x", "unit", "s", "higherIsBetter", true)).post(TYPES).then().statusCode(403);
        member(TENANT, TenantRole.ADMIN);
        String id = api(TENANT).body(Map.of("code", "ONLY_TENANT_A", "name", "A only", "unit", "s", "higherIsBetter", true))
                .post(TYPES).then().statusCode(201).extract().path("id");
        core.knownPlayers(OTHER_TENANT, GIRL);
        member(OTHER_TENANT, TenantRole.ADMIN);

        api(OTHER_TENANT).get(TYPES).then().statusCode(200).body("code", not(hasItem("ONLY_TENANT_A")))
                .body("code", hasItem("COOPER_12MIN"));
        api(OTHER_TENANT).get(TYPES + "/" + id).then().statusCode(404);
        lenient(OTHER_TENANT).body(Map.of("name", "stolen")).patch(TYPES + "/" + id).then().statusCode(404);
        // the same code is free in the other tenant
        api(OTHER_TENANT).body(Map.of("code", "ONLY_TENANT_A", "name", "B", "unit", "s", "higherIsBetter", true)).post(TYPES)
                .then().statusCode(201);
    }

    // ------------------------------------------------------------------ results and expected band
    @Test
    void aResultCarriesTheExpectedBandFromTheGlobalNorms() {
        String cooper = typeId("COOPER_12MIN");

        // girl born 2012-05-01, tested 2026-06-01: 14 years old; Cooper (1968) girls 13-14: 1600-1900 m is average
        api(TENANT).body(result(GIRL, cooper, "2026-06-01", 1700.0)).post(RESULTS).then().statusCode(201)
                .body("testCode", equalTo("COOPER_12MIN")).body("unit", equalTo("m")).body("value", equalTo(1700.0f))
                .body("ageAtMeasurement", equalTo(14)).body("expectedBand", equalTo("AVERAGE"))
                .body("normId", notNullValue()).body("referencePending", equalTo(false))
                .body("recordedBy.personId", notNullValue());
        api(TENANT).body(result(GIRL, cooper, "2026-06-02", 2050.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", equalTo("EXCELLENT"));
        api(TENANT).body(result(GIRL, cooper, "2026-06-03", 1400.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", equalTo("POOR"));
    }

    @Test
    void aPlaceholderNormGivesABandButIsFlaggedReferencePending() {
        api(TENANT).body(result(BOY, typeId("SPRINT_20M"), "2026-06-01", 3.9)).post(RESULTS).then().statusCode(201)
                .body("ageAtMeasurement", equalTo(16)).body("expectedBand", notNullValue()).body("referencePending", equalTo(true));
    }

    @Test
    void ageIsCountedOnTheMeasurementDateNotToday() {
        String cooper = typeId("COOPER_12MIN");

        // 1650 m: girls 13-14 are AVERAGE (1600-1900 m), girls 15-16 BELOW_AVERAGE (1600-1700 m)
        api(TENANT).body(result(GIRL, cooper, "2027-04-30", 1650.0)).post(RESULTS).then().statusCode(201)
                .body("ageAtMeasurement", equalTo(14)).body("expectedBand", equalTo("AVERAGE"));
        api(TENANT).body(result(GIRL, cooper, "2027-05-01", 1650.0)).post(RESULTS).then().statusCode(201)
                .body("ageAtMeasurement", equalTo(15)).body("expectedBand", equalTo("BELOW_AVERAGE"));
    }

    @Test
    void missingBirthDateOrGenderOrNormGivesNoBandAndTheReasonFlag() {
        String cooper = typeId("COOPER_12MIN");
        api(TENANT).body(result(NO_BIRTH, cooper, "2026-06-01", 2000.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", nullValue()).body("normId", nullValue()).body("bandStatus", equalTo("MISSING_PLAYER_DATA"))
                .body("ageAtMeasurement", nullValue()).body("referencePending", equalTo(false));
        api(TENANT).body(result(NO_GENDER, cooper, "2026-06-01", 2000.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", nullValue()).body("bandStatus", equalTo("MISSING_PLAYER_DATA"));

        String custom = api(TENANT).body(Map.of("code", "NO_NORMS_YET", "name", "Plank", "unit", "s", "higherIsBetter", true))
                .post(TYPES).then().statusCode(201).extract().path("id");
        api(TENANT).body(result(GIRL, custom, "2026-06-01", 60.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", nullValue()).body("bandStatus", equalTo("NO_NORM"));
        // the tables start at age 8, so a 7 year old has no norm
        api(TENANT).body(result(GIRL, cooper, "2019-06-01", 1000.0)).post(RESULTS).then().statusCode(201)
                .body("ageAtMeasurement", equalTo(7)).body("expectedBand", nullValue()).body("bandStatus", equalTo("NO_NORM"));
    }

    @Test
    void aTenantOverrideBeatsTheGlobalNormAndDeletingItRestoresTheGlobalOne() {
        String cooper = typeId("COOPER_12MIN");
        // this academy rates a girl of 13-14 as EXCELLENT from 1500 m
        String override = api(TENANT).body(norm(cooper, "FEMALE", 13, 14, "EXCELLENT", 1500.0, 2500.0, "Academy 2026 standard"))
                .post(NORMS).then().statusCode(201).body("global", equalTo(false)).body("referencePending", equalTo(false))
                .extract().path("id");

        api(TENANT).body(result(GIRL, cooper, "2026-06-01", 1700.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", equalTo("EXCELLENT")).body("normId", equalTo(override));

        String resultId = api(TENANT).body(result(GIRL, cooper, "2026-06-05", 1700.0)).post(RESULTS).then().extract().path("id");
        api(TENANT).delete(NORMS + "/" + override).then().statusCode(204);
        api(TENANT).get(RESULTS + "/" + resultId).then().statusCode(200).body("expectedBand", equalTo("AVERAGE"));
    }

    @Test
    void anOverrideWithoutASourceIsReferencePendingAndAppliesOnlyToItsTenant() {
        String sprint = typeId("SPRINT_20M");
        String override = api(TENANT).body(norm(sprint, "MALE", 16, 16, "EXCELLENT", null, 9.0, null)).post(NORMS)
                .then().statusCode(201).body("referencePending", equalTo(true)).extract().path("id");
        core.knownPlayerData(OTHER_TENANT, new String[] {BOY, "2010-01-15", "MALE"});
        core.roster(OTHER_TENANT, TEAM, BOY);

        api(TENANT).body(result(BOY, sprint, "2026-06-01", 8.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", equalTo("EXCELLENT")).body("referencePending", equalTo(true));
        member(OTHER_TENANT, TenantRole.ADMIN);
        api(OTHER_TENANT).body(result(BOY, sprint, "2026-06-01", 8.0)).post(RESULTS).then().statusCode(201)
                .body("expectedBand", equalTo("POOR"));
        api(OTHER_TENANT).delete(NORMS + "/" + override).then().statusCode(404);
    }

    @Test
    void resultsAreListedFilteredCorrectedAndDeleted() {
        String vertical = typeId("VERTICAL_JUMP");
        String cooper = typeId("COOPER_12MIN");
        String jump = api(TENANT).body(result(BOY, vertical, "2026-02-01", 35.0)).post(RESULTS).then().statusCode(201).extract().path("id");
        api(TENANT).body(result(BOY, cooper, "2026-03-01", 2500.0)).post(RESULTS).then().statusCode(201);

        api(TENANT).queryParam("playerId", BOY).queryParam("testTypeId", vertical).get(RESULTS).then().statusCode(200)
                .body("items.testCode", everyItem(equalTo("VERTICAL_JUMP"))).body("items.id", hasItem(jump));
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2026-02-01").queryParam("to", "2026-03-31").get(RESULTS)
                .then().statusCode(200).body("page.totalElements", greaterThanOrEqualTo(2));
        api(TENANT).body(Map.of("value", 48.0, "notes", "re-test")).patch(RESULTS + "/" + jump).then().statusCode(200)
                .body("value", equalTo(48.0f)).body("notes", equalTo("re-test")).body("expectedBand", notNullValue());
        api(TENANT).body(Map.of("measuredOn", "2026-02-02")).patch(RESULTS + "/" + jump).then().statusCode(200)
                .body("ageAtMeasurement", equalTo(16));
        api(TENANT).delete(RESULTS + "/" + jump).then().statusCode(204);
        api(TENANT).get(RESULTS + "/" + jump).then().statusCode(404);
    }

    @Test
    void resultValidationAndRejections() {
        String cooper = typeId("COOPER_12MIN");
        lenient(TENANT).body(result(GIRL, cooper, "2026-06-01", -5.0)).post(RESULTS).then().statusCode(422)
                .body("code", equalTo("RESULT_VALUE_NEGATIVE"));
        api(TENANT).body(result(GIRL, UUID.randomUUID().toString(), "2026-06-01", 5.0)).post(RESULTS).then().statusCode(404);
        api(TENANT).body(result(UUID.randomUUID().toString(), cooper, "2026-06-01", 5.0)).post(RESULTS).then().statusCode(404);
        lenient(TENANT).body(Map.of("playerId", GIRL)).post(RESULTS).then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch(RESULTS + "/" + UUID.randomUUID()).then().statusCode(400);
    }

    @Test
    void parentsAndPlayersReadButNeverWriteResults() {
        String cooper = typeId("COOPER_12MIN");
        String own = api(TENANT).body(result(GIRL, cooper, "2026-06-10", 1700.0)).post(RESULTS).then().statusCode(201).extract().path("id");
        String other = api(TENANT).body(result(BOY, cooper, "2026-06-10", 2500.0)).post(RESULTS).then().statusCode(201).extract().path("id");

        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(GIRL), null);
        api(TENANT).get(RESULTS + "/" + own).then().statusCode(200).body("expectedBand", equalTo("AVERAGE"));
        api(TENANT).get(RESULTS + "/" + other).then().statusCode(404);
        api(TENANT).get(RESULTS).then().statusCode(200).body("items.playerId", everyItem(equalTo(GIRL)));
        api(TENANT).body(result(GIRL, cooper, "2026-06-11", 1700.0)).post(RESULTS).then().statusCode(403);
        api(TENANT).body(Map.of("value", 1.0)).patch(RESULTS + "/" + own).then().statusCode(403);
        api(TENANT).delete(RESULTS + "/" + own).then().statusCode(403);

        member(TENANT, Set.of(TenantRole.PLAYER), Set.of(), Set.of(), BOY);
        api(TENANT).get(RESULTS + "/" + other).then().statusCode(200);
        api(TENANT).get(RESULTS + "/" + own).then().statusCode(404);
        api(TENANT).body(result(BOY, cooper, "2026-06-11", 1700.0)).post(RESULTS).then().statusCode(403);
    }

    @Test
    void teamStaffWriteResultsOnlyForTheirOwnPlayers() {
        String cooper = typeId("COOPER_12MIN");
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);
        api(TENANT).body(result(GIRL, cooper, "2026-06-12", 1700.0)).post(RESULTS).then().statusCode(201);

        String otherTeam = "68000000-0000-4000-8000-0000000000a2";
        member(TENANT, Set.of(TenantRole.COACH), Set.of(otherTeam), Set.of(), null);
        core.roster(TENANT, otherTeam, UUID.randomUUID().toString());
        api(TENANT).body(result(GIRL, cooper, "2026-06-12", 1700.0)).post(RESULTS).then().statusCode(403);
    }

    // ------------------------------------------------------------------ norms
    @Test
    void normListFiltersByScopeTestAndGender() {
        String sprint = typeId("SPRINT_20M");
        String tenantNorm = api(TENANT).body(norm(sprint, "FEMALE", 12, 13, "AVERAGE", 3.9, 4.2, "Academy table")).post(NORMS)
                .then().statusCode(201).extract().path("id");

        api(TENANT).queryParam("scope", "GLOBAL").queryParam("testTypeId", sprint).get(NORMS).then().statusCode(200)
                .body("global", everyItem(equalTo(true))).body("id", not(hasItem(tenantNorm))).body("size()", greaterThanOrEqualTo(55));
        api(TENANT).queryParam("scope", "TENANT").get(NORMS).then().statusCode(200)
                .body("global", everyItem(equalTo(false))).body("id", hasItem(tenantNorm));
        // effective: the tenant row replaces the global FEMALE 12 and 13 rows of the same test, the rest stays
        api(TENANT).queryParam("testTypeId", sprint).queryParam("gender", "FEMALE").get(NORMS).then().statusCode(200)
                .body("id", hasItem(tenantNorm))
                .body("findAll { it.global && it.minAge >= 12 && it.maxAge <= 13 }", hasSize(0))
                .body("findAll { it.global && it.minAge == 14 }", hasSize(5))
                .body("gender", everyItem(equalTo("FEMALE")));
        api(TENANT).queryParam("scope", "GLOBAL").queryParam("testTypeId", sprint).queryParam("gender", "MALE").get(NORMS)
                .then().body("gender", everyItem(equalTo("MALE")));
        lenient(TENANT).queryParam("scope", "EVERYTHING").get(NORMS).then().statusCode(400);
        member(TENANT, Set.of(TenantRole.PLAYER), Set.of(), Set.of(), GIRL);
        api(TENANT).queryParam("scope", "GLOBAL").get(NORMS).then().statusCode(200);
    }

    @Test
    void globalNormsAreReadOnlyAndOnlyAdminsWriteNorms() {
        String sprint = typeId("SPRINT_20M");
        String globalNorm = api(TENANT).queryParam("scope", "GLOBAL").queryParam("testTypeId", sprint).get(NORMS).then()
                .extract().path("[0].id");

        lenient(TENANT).body(norm(sprint, "MALE", 10, 10, "AVERAGE", 1.0, 2.0, "x")).put(NORMS + "/" + globalNorm).then().statusCode(403)
                .body("code", equalTo("NORM_IS_GLOBAL"));
        lenient(TENANT).delete(NORMS + "/" + globalNorm).then().statusCode(403).body("code", equalTo("NORM_IS_GLOBAL"));

        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);
        lenient(TENANT).body(norm(sprint, "MALE", 10, 10, "AVERAGE", 1.0, 2.0, "x")).post(NORMS).then().statusCode(403);
        member(TENANT, TenantRole.ADMIN);
        api(TENANT).delete(NORMS + "/" + UUID.randomUUID()).then().statusCode(404);
        api(TENANT).body(norm(UUID.randomUUID().toString(), "MALE", 10, 10, "AVERAGE", 1.0, 2.0, "x")).post(NORMS).then().statusCode(404);
    }

    @Test
    void tenantNormsValidateRangesAndRejectOverlappingAgesForTheSameBand() {
        String beep = typeId("BEEP_TEST");
        String first = api(TENANT).body(norm(beep, "MALE", 10, 12, "AVERAGE", 5.0, 7.0, "Academy"))
                .post(NORMS).then().statusCode(201).extract().path("id");

        lenient(TENANT).body(norm(beep, "MALE", 12, 14, "AVERAGE", 5.0, 7.0, "Academy")).post(NORMS).then().statusCode(409)
                .body("code", equalTo("NORM_RANGE_OVERLAP"));
        api(TENANT).body(norm(beep, "MALE", 12, 14, "EXCELLENT", 9.0, null, "Academy")).post(NORMS).then().statusCode(201);
        api(TENANT).body(norm(beep, "FEMALE", 12, 14, "AVERAGE", 5.0, 7.0, "Academy")).post(NORMS).then().statusCode(201);
        lenient(TENANT).body(norm(beep, "MALE", 11, 13, "AVERAGE", 5.0, 7.0, "Academy")).post(NORMS).then().statusCode(409);
        api(TENANT).body(norm(beep, "MALE", 13, 15, "AVERAGE", 6.0, 8.0, "Academy")).post(NORMS).then().statusCode(201);

        lenient(TENANT).body(norm(beep, "MALE", 16, 14, "POOR", 1.0, 2.0, "Academy")).post(NORMS).then().statusCode(422)
                .body("code", equalTo("NORM_INVALID_AGE_RANGE"));
        lenient(TENANT).body(norm(beep, "MALE", 16, 18, "POOR", 2.0, 1.0, "Academy")).post(NORMS).then().statusCode(422)
                .body("code", equalTo("NORM_INVALID_VALUE_RANGE"));

        // replacing a row keeps its identity and does not collide with itself
        api(TENANT).body(norm(beep, "MALE", 10, 12, "AVERAGE", 5.5, 7.5, "Academy v2")).put(NORMS + "/" + first).then().statusCode(200)
                .body("id", equalTo(first)).body("minValue", equalTo(5.5f)).body("source", equalTo("Academy v2"));
        lenient(TENANT).body(norm(beep, "MALE", 12, 14, "AVERAGE", 5.5, 7.5, "Academy")).put(NORMS + "/" + first).then().statusCode(409)
                .body("code", equalTo("NORM_RANGE_OVERLAP"));
    }
}
