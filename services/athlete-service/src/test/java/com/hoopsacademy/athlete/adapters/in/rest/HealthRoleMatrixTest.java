package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.ADMIN;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.ADMIN_AND_PLAYER;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.ASSISTANT_OF_TEAM;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.COACH_AND_PARENT;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.COACH_OF_OTHER;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.COACH_OF_TEAM;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.NO_ROLE;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PARENT_LINKED;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PARENT_UNLINKED;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PLAYER_OTHER;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PLAYER_SELF;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.unvalidated;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.Caller;
import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * docs/domain/authz-matrix.md for health data: injuries and height / weight (staff of the player's team, ADMIN, linked
 * parent write; the player reads self) and test results (staff write, parent / player read). Test types and norms:
 * everyone reads, ADMIN writes. 2xx = allowed, 403 = member without the right, 404 = hidden.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class HealthRoleMatrixTest {

    static final String TENANT = "69000000-0000-4000-8000-000000000001";
    // the callers of RoleMatrixTest, in a tenant of their own
    static final String TEAM = "55000000-0000-4000-8000-0000000000a1";
    static final String OTHER_TEAM = "55000000-0000-4000-8000-0000000000a2";
    static final String CHILD = "55000000-0000-4000-8000-0000000000b1";
    static final String OTHER = "55000000-0000-4000-8000-0000000000b2";
    static final String INJURIES = "/api/athlete/injuries";
    static final String MEASUREMENTS = "/api/athlete/body-measurements";
    static final String RESULTS = "/api/athlete/physical-test-results";
    static final AtomicInteger DAYS = new AtomicInteger();

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;
    String testType;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, CHILD).roster(TENANT, OTHER_TEAM, OTHER).knownPlayers(TENANT, CHILD, OTHER);
        act(ADMIN);
        testType = lenient(TENANT).get("/api/athlete/physical-test-types").then().extract().path("find { it.code == 'COOPER_12MIN' }.id");
    }

    private void act(Caller c) {
        member(TENANT, c.roles(), c.staffTeams(), c.linked(), c.own());
    }

    private static String day() {
        return LocalDate.of(2020, 1, 1).plusDays(DAYS.incrementAndGet()).toString();
    }

    private Map<String, Object> injury() {
        return Map.of("playerId", CHILD, "occurredOn", "2026-10-01", "bodyPart", "knee", "severity", "MINOR");
    }

    private String injuryId() {
        act(ADMIN);
        return unvalidated(TENANT).body(injury()).post(INJURIES).then().statusCode(201).extract().path("id");
    }

    private String measurementId() {
        act(ADMIN);
        return unvalidated(TENANT).body(Map.of("playerId", CHILD, "measuredOn", day(), "heightCm", 150.0)).post(MEASUREMENTS)
                .then().statusCode(201).extract().path("id");
    }

    private String resultId() {
        act(ADMIN);
        return unvalidated(TENANT).body(Map.of("playerId", CHILD, "testTypeId", testType, "measuredOn", "2026-10-01", "value", 2000.0))
                .post(RESULTS).then().statusCode(201).extract().path("id");
    }

    // ------------------------------------------------------------------ who may write health data of CHILD
    static Stream<Arguments> writeHealth() {
        return Stream.of(
                Arguments.of(ADMIN, 201), Arguments.of(COACH_OF_TEAM, 201), Arguments.of(ASSISTANT_OF_TEAM, 201),
                Arguments.of(COACH_OF_OTHER, 403), Arguments.of(PARENT_LINKED, 201), Arguments.of(PARENT_UNLINKED, 403),
                Arguments.of(PLAYER_SELF, 403), Arguments.of(PLAYER_OTHER, 403), Arguments.of(COACH_AND_PARENT, 201),
                Arguments.of(ADMIN_AND_PLAYER, 201), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "report injury: {0} -> {1}")
    @MethodSource("writeHealth")
    void createInjury(Caller caller, int expected) {
        act(caller);
        assertThat(unvalidated(TENANT).body(injury()).post(INJURIES).then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "record height/weight: {0} -> {1}")
    @MethodSource("writeHealth")
    void createMeasurement(Caller caller, int expected) {
        act(caller);
        assertThat(unvalidated(TENANT).body(Map.of("playerId", CHILD, "measuredOn", day(), "heightCm", 150.0, "weightKg", 40.0))
                .post(MEASUREMENTS).then().extract().statusCode()).isEqualTo(expected);
    }

    // ------------------------------------------------------------------ update: unseen = 404, seen but not allowed = 403
    static Stream<Arguments> updateHealth() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(ASSISTANT_OF_TEAM, 200),
                Arguments.of(COACH_OF_OTHER, 404), Arguments.of(PARENT_LINKED, 200), Arguments.of(PARENT_UNLINKED, 404),
                Arguments.of(PLAYER_SELF, 403), Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 200),
                Arguments.of(ADMIN_AND_PLAYER, 200), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "update injury: {0} -> {1}")
    @MethodSource("updateHealth")
    void updateInjury(Caller caller, int expected) {
        String id = injuryId();
        act(caller);
        assertThat(unvalidated(TENANT).body(Map.of("bodyPart", "hip")).patch(INJURIES + "/" + id).then().extract().statusCode())
                .isEqualTo(expected);
    }

    @ParameterizedTest(name = "update measurement: {0} -> {1}")
    @MethodSource("updateHealth")
    void updateMeasurement(Caller caller, int expected) {
        String id = measurementId();
        act(caller);
        assertThat(unvalidated(TENANT).body(Map.of("heightCm", 151.0)).patch(MEASUREMENTS + "/" + id).then().extract().statusCode())
                .isEqualTo(expected);
    }

    @ParameterizedTest(name = "delete measurement: {0} -> {1}")
    @MethodSource("deleteMeasurement")
    void deleteMeasurement(Caller caller, int expected) {
        String id = measurementId();
        act(caller);
        assertThat(unvalidated(TENANT).delete(MEASUREMENTS + "/" + id).then().extract().statusCode()).isEqualTo(expected);
    }

    static Stream<Arguments> deleteMeasurement() {
        return updateHealth().map(a -> Arguments.of(a.get()[0], switch ((Integer) a.get()[1]) {
            case 200 -> 204;
            default -> a.get()[1];
        }));
    }

    // injuries are deleted by ADMIN and team staff only (the parent may report and correct, not delete)
    static Stream<Arguments> deleteInjury() {
        return Stream.of(
                Arguments.of(ADMIN, 204), Arguments.of(COACH_OF_TEAM, 204), Arguments.of(ASSISTANT_OF_TEAM, 204),
                Arguments.of(COACH_OF_OTHER, 404), Arguments.of(PARENT_LINKED, 403), Arguments.of(PARENT_UNLINKED, 404),
                Arguments.of(PLAYER_SELF, 403), Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 403),
                Arguments.of(ADMIN_AND_PLAYER, 204), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "delete injury: {0} -> {1}")
    @MethodSource("deleteInjury")
    void deleteInjury(Caller caller, int expected) {
        String id = injuryId();
        act(caller);
        assertThat(unvalidated(TENANT).delete(INJURIES + "/" + id).then().extract().statusCode()).isEqualTo(expected);
    }

    // ------------------------------------------------------------------ reads of CHILD's data
    static Stream<Arguments> readHealth() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(ASSISTANT_OF_TEAM, 200),
                Arguments.of(COACH_OF_OTHER, 404), Arguments.of(PARENT_LINKED, 200), Arguments.of(PARENT_UNLINKED, 404),
                Arguments.of(PLAYER_SELF, 200), Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 200),
                Arguments.of(ADMIN_AND_PLAYER, 200), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "read injury: {0} -> {1}")
    @MethodSource("readHealth")
    void readInjury(Caller caller, int expected) {
        String id = injuryId();
        act(caller);
        assertThat(unvalidated(TENANT).get(INJURIES + "/" + id).then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "player availability: {0} -> {1}")
    @MethodSource("readHealth")
    void readAvailability(Caller caller, int expected) {
        act(caller);
        assertThat(api(TENANT).get("/api/athlete/players/" + CHILD + "/availability").then().extract().statusCode())
                .isEqualTo(expected);
    }

    @ParameterizedTest(name = "read test result: {0} -> {1}")
    @MethodSource("readHealth")
    void readResult(Caller caller, int expected) {
        String id = resultId();
        act(caller);
        assertThat(unvalidated(TENANT).get(RESULTS + "/" + id).then().extract().statusCode()).isEqualTo(expected);
    }

    // measurement history is asked by player id: naming a player the caller may not see is 403 (as for planned absences)
    static Stream<Arguments> historyOfChild() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(COACH_OF_OTHER, 403),
                Arguments.of(PARENT_LINKED, 200), Arguments.of(PARENT_UNLINKED, 403), Arguments.of(PLAYER_SELF, 200),
                Arguments.of(PLAYER_OTHER, 403), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "measurement history: {0} -> {1}")
    @MethodSource("historyOfChild")
    void measurementHistory(Caller caller, int expected) {
        act(caller);
        assertThat(unvalidated(TENANT).queryParam("playerId", CHILD).get(MEASUREMENTS).then().extract().statusCode()).isEqualTo(expected);
    }

    // ------------------------------------------------------------------ results: staff of the player's team write
    static Stream<Arguments> writeResult() {
        return Stream.of(
                Arguments.of(ADMIN, 201), Arguments.of(COACH_OF_TEAM, 201), Arguments.of(ASSISTANT_OF_TEAM, 201),
                Arguments.of(COACH_OF_OTHER, 403), Arguments.of(PARENT_LINKED, 403), Arguments.of(PARENT_UNLINKED, 403),
                Arguments.of(PLAYER_SELF, 403), Arguments.of(PLAYER_OTHER, 403), Arguments.of(COACH_AND_PARENT, 403),
                Arguments.of(ADMIN_AND_PLAYER, 201), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "record test result: {0} -> {1}")
    @MethodSource("writeResult")
    void createResult(Caller caller, int expected) {
        act(caller);
        assertThat(unvalidated(TENANT).body(Map.of("playerId", CHILD, "testTypeId", testType, "measuredOn", "2026-10-02", "value", 1800.0))
                .post(RESULTS).then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "delete test result: {0}")
    @MethodSource("deleteResult")
    void deleteResult(Caller caller, int expected) {
        String id = resultId();
        act(caller);
        assertThat(unvalidated(TENANT).delete(RESULTS + "/" + id).then().extract().statusCode()).isEqualTo(expected);
    }

    static Stream<Arguments> deleteResult() {
        return Stream.of(
                Arguments.of(ADMIN, 204), Arguments.of(COACH_OF_TEAM, 204), Arguments.of(COACH_OF_OTHER, 404),
                Arguments.of(PARENT_LINKED, 403), Arguments.of(PARENT_UNLINKED, 404), Arguments.of(PLAYER_SELF, 403),
                Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 403), Arguments.of(NO_ROLE, 403));
    }

    // ------------------------------------------------------------------ types and norms: everyone reads, ADMIN writes
    static Stream<Arguments> adminOnly() {
        return Stream.of(
                Arguments.of(ADMIN, true), Arguments.of(COACH_OF_TEAM, false), Arguments.of(ASSISTANT_OF_TEAM, false),
                Arguments.of(PARENT_LINKED, false), Arguments.of(PLAYER_SELF, false), Arguments.of(COACH_AND_PARENT, false),
                Arguments.of(ADMIN_AND_PLAYER, true), Arguments.of(NO_ROLE, false));
    }

    @ParameterizedTest(name = "create tenant test type: {0} allowed={1}")
    @MethodSource("adminOnly")
    void createTestType(Caller caller, boolean allowed) {
        act(caller);
        String code = "MX_" + DAYS.incrementAndGet();
        int status = unvalidated(TENANT).body(Map.of("code", code, "name", "x", "unit", "s", "higherIsBetter", true))
                .post("/api/athlete/physical-test-types").then().extract().statusCode();
        assertThat(status).isEqualTo(allowed ? 201 : 403);
    }

    private String customTestType() {
        act(ADMIN);
        return unvalidated(TENANT).body(Map.of("code", "MX_" + DAYS.incrementAndGet(), "name", "x", "unit", "s",
                "higherIsBetter", true)).post("/api/athlete/physical-test-types").then().statusCode(201).extract().path("id");
    }

    @ParameterizedTest(name = "update tenant test type: {0} allowed={1}")
    @MethodSource("adminOnly")
    void updateTestType(Caller caller, boolean allowed) {
        String id = customTestType();
        act(caller);
        int status = unvalidated(TENANT).body(Map.of("code", "MY_" + DAYS.incrementAndGet(), "name", "renamed"))
                .patch("/api/athlete/physical-test-types/" + id).then().extract().statusCode();
        assertThat(status).isEqualTo(allowed ? 200 : 403);
    }

    @ParameterizedTest(name = "delete tenant test type: {0} allowed={1}")
    @MethodSource("adminOnly")
    void deleteTestType(Caller caller, boolean allowed) {
        String id = customTestType();
        act(caller);
        int status = unvalidated(TENANT).delete("/api/athlete/physical-test-types/" + id).then().extract().statusCode();
        assertThat(status).isEqualTo(allowed ? 204 : 403);
    }

    @ParameterizedTest(name = "create tenant norm: {0} allowed={1}")
    @MethodSource("adminOnly")
    void createNorm(Caller caller, boolean allowed) {
        act(caller);
        int age = 20 + DAYS.incrementAndGet() % 70;
        int status = unvalidated(TENANT).body(Map.of("testTypeId", testType, "gender", "MALE", "minAge", age, "maxAge", age,
                "band", "AVERAGE", "minValue", 1.0, "maxValue", 2.0, "source", "x")).post("/api/athlete/physical-test-norms")
                .then().extract().statusCode();
        assertThat(status).isEqualTo(allowed ? 201 : 403);
    }

    static Stream<Arguments> everyMember() {
        return Stream.of(Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_OTHER, 200), Arguments.of(PARENT_UNLINKED, 200),
                Arguments.of(PLAYER_OTHER, 200), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "list test types and norms: {0} -> {1}")
    @MethodSource("everyMember")
    void listTypesAndNorms(Caller caller, int expected) {
        act(caller);
        assertThat(unvalidated(TENANT).get("/api/athlete/physical-test-types").then().extract().statusCode()).isEqualTo(expected);
        assertThat(unvalidated(TENANT).get("/api/athlete/physical-test-norms").then().extract().statusCode()).isEqualTo(expected);
    }
}
