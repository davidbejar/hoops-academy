package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.assertj.core.api.Assertions.assertThat;

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
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * docs/domain/authz-matrix.md as an oracle for training data: schedule/session/attendance writes, attendance reads
 * and planned absences, for every role and the unions that matter. Statuses: 2xx = allowed, 403 = member without the
 * right, 404 = hidden.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class RoleMatrixTest {

    static final String TENANT = "55000000-0000-4000-8000-000000000001";
    static final String TEAM = "55000000-0000-4000-8000-0000000000a1";
    static final String OTHER_TEAM = "55000000-0000-4000-8000-0000000000a2";
    static final String CHILD = "55000000-0000-4000-8000-0000000000b1";
    static final String OTHER = "55000000-0000-4000-8000-0000000000b2";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    /** A caller definition: roles plus relations. */
    record Caller(String name, Set<TenantRole> roles, Set<String> staffTeams, Set<String> linked, String own) {
        @Override
        public String toString() {
            return name;
        }
    }

    static final Caller ADMIN = new Caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null);
    static final Caller COACH_OF_TEAM = new Caller("COACH of team", Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);
    static final Caller ASSISTANT_OF_TEAM = new Caller("ASSISTANT_COACH of team", Set.of(TenantRole.ASSISTANT_COACH), Set.of(TEAM), Set.of(), null);
    static final Caller COACH_OF_OTHER = new Caller("COACH of other team", Set.of(TenantRole.COACH), Set.of(OTHER_TEAM), Set.of(), null);
    static final Caller PARENT_LINKED = new Caller("PARENT linked", Set.of(TenantRole.PARENT), Set.of(), Set.of(CHILD), null);
    static final Caller PARENT_UNLINKED = new Caller("PARENT unlinked", Set.of(TenantRole.PARENT), Set.of(), Set.of(OTHER), null);
    static final Caller PLAYER_SELF = new Caller("PLAYER self", Set.of(TenantRole.PLAYER), Set.of(), Set.of(), CHILD);
    static final Caller PLAYER_OTHER = new Caller("PLAYER other", Set.of(TenantRole.PLAYER), Set.of(), Set.of(), OTHER);
    static final Caller COACH_AND_PARENT = new Caller("COACH(other team)+PARENT(linked)",
            Set.of(TenantRole.COACH, TenantRole.PARENT), Set.of(OTHER_TEAM), Set.of(CHILD), null);
    static final Caller ADMIN_AND_PLAYER = new Caller("ADMIN+PLAYER", Set.of(TenantRole.ADMIN, TenantRole.PLAYER), Set.of(), Set.of(), OTHER);
    static final Caller NO_ROLE = new Caller("member without role", Set.of(), Set.of(), Set.of(), null);

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, CHILD).roster(TENANT, OTHER_TEAM, OTHER).knownPlayers(TENANT, CHILD, OTHER);
    }

    private void actAs(Caller c) {
        member(TENANT, c.roles(), c.staffTeams(), c.linked(), c.own());
    }

    private void actAsAdmin() {
        actAs(ADMIN);
    }

    private String adminSession() {
        actAsAdmin();
        return api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2028-01-10T17:00:00Z", "durationMinutes", 60))
                .post("/api/athlete/training-sessions").then().statusCode(201).extract().path("id");
    }

    // ------------------------------------------------------------------ writes by team staff / admin
    static Stream<Arguments> teamWrite() {
        return Stream.of(
                Arguments.of(ADMIN, true), Arguments.of(COACH_OF_TEAM, true), Arguments.of(ASSISTANT_OF_TEAM, true),
                Arguments.of(COACH_OF_OTHER, false), Arguments.of(PARENT_LINKED, false), Arguments.of(PLAYER_SELF, false),
                Arguments.of(COACH_AND_PARENT, false), Arguments.of(ADMIN_AND_PLAYER, true), Arguments.of(NO_ROLE, false));
    }

    @ParameterizedTest(name = "create schedule: {0} allowed={1}")
    @MethodSource("teamWrite")
    void createSchedule(Caller caller, boolean allowed) {
        actAs(caller);
        var body = Map.of("teamId", TEAM, "dayOfWeek", "MONDAY", "startTime", "18:00", "durationMinutes", 60,
                "validFrom", "2028-01-01", "validUntil", "2028-01-31");

        int status = lenient(TENANT).body(body).post("/api/athlete/training-schedules").then().extract().statusCode();

        assertThat(status).isEqualTo(allowed ? 201 : 403);
    }

    @ParameterizedTest(name = "create ad-hoc session: {0} allowed={1}")
    @MethodSource("teamWrite")
    void createSession(Caller caller, boolean allowed) {
        actAs(caller);

        int status = api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2028-02-01T17:00:00Z", "durationMinutes", 60))
                .post("/api/athlete/training-sessions").then().extract().statusCode();

        assertThat(status).isEqualTo(allowed ? 201 : 403);
    }

    @ParameterizedTest(name = "record attendance: {0} allowed={1}")
    @MethodSource("teamWrite")
    void recordAttendance(Caller caller, boolean allowed) {
        String session = adminSession();
        actAs(caller);

        int status = api(TENANT).body(Map.of("entries", List.of(Map.of("playerId", CHILD, "status", "PRESENT"))))
                .put("/api/athlete/training-sessions/" + session + "/attendance").then().extract().statusCode();

        assertThat(status).isEqualTo(allowed ? 200 : 403);
    }

    @ParameterizedTest(name = "cancel session: {0} allowed={1}")
    @MethodSource("teamWrite")
    void cancelSession(Caller caller, boolean allowed) {
        String session = adminSession();
        actAs(caller);

        int status = api(TENANT).body(Map.of("reason", "x")).post("/api/athlete/training-sessions/" + session + "/cancel")
                .then().extract().statusCode();

        assertThat(status).isEqualTo(allowed ? 200 : 403);
    }

    // ------------------------------------------------------------------ attendance sheet reads
    static Stream<Arguments> sheetRead() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(ASSISTANT_OF_TEAM, 200),
                Arguments.of(COACH_OF_OTHER, 403), Arguments.of(PARENT_LINKED, 200), Arguments.of(PARENT_UNLINKED, 404),
                Arguments.of(PLAYER_SELF, 200), Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 200));
    }

    @ParameterizedTest(name = "attendance sheet: {0} -> {1}")
    @MethodSource("sheetRead")
    void readAttendanceSheet(Caller caller, int expected) {
        String session = adminSession();
        actAs(caller);

        int status = api(TENANT).get("/api/athlete/training-sessions/" + session + "/attendance").then().extract().statusCode();

        assertThat(status).isEqualTo(expected);
    }

    // ------------------------------------------------------------------ session reads
    static Stream<Arguments> sessionRead() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(COACH_OF_OTHER, 200),
                Arguments.of(PARENT_LINKED, 200), Arguments.of(PARENT_UNLINKED, 404), Arguments.of(PLAYER_SELF, 200),
                Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 200));
    }

    @ParameterizedTest(name = "read session: {0} -> {1}")
    @MethodSource("sessionRead")
    void readSession(Caller caller, int expected) {
        String session = adminSession();
        actAs(caller);

        int status = api(TENANT).get("/api/athlete/training-sessions/" + session).then().extract().statusCode();

        assertThat(status).isEqualTo(expected);
    }

    // ------------------------------------------------------------------ planned absences for CHILD
    static Stream<Arguments> absenceForChild() {
        return Stream.of(
                Arguments.of(ADMIN, 201), Arguments.of(COACH_OF_TEAM, 201), Arguments.of(ASSISTANT_OF_TEAM, 201),
                Arguments.of(COACH_OF_OTHER, 201), Arguments.of(PARENT_LINKED, 201), Arguments.of(PARENT_UNLINKED, 403),
                Arguments.of(PLAYER_SELF, 201), Arguments.of(PLAYER_OTHER, 403), Arguments.of(COACH_AND_PARENT, 201),
                Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "planned absence for CHILD: {0} -> {1}")
    @MethodSource("absenceForChild")
    void createAbsence(Caller caller, int expected) {
        actAs(caller);

        int status = api(TENANT).body(Map.of("playerId", CHILD, "fromDate", "2028-03-01", "toDate", "2028-03-02"))
                .post("/api/athlete/planned-absences").then().extract().statusCode();

        assertThat(status).isEqualTo(expected);
    }

    @ParameterizedTest(name = "delete planned absence of CHILD: {0} -> {1}")
    @MethodSource("absenceForChild")
    void deleteAbsence(Caller caller, int createdStatus) {
        actAsAdmin();
        String id = api(TENANT).body(Map.of("playerId", CHILD, "fromDate", "2028-04-01", "toDate", "2028-04-02"))
                .post("/api/athlete/planned-absences").then().statusCode(201).extract().path("id");
        actAs(caller);

        int status = api(TENANT).delete("/api/athlete/planned-absences/" + id).then().extract().statusCode();

        // allowed callers get 204; a member without any role is stopped by the role check (403); the others cannot even
        // see the absence of a player they have no relation to (404)
        int expected = createdStatus == 201 ? 204 : caller == NO_ROLE ? 403 : 404;
        assertThat(status).isEqualTo(expected);
    }
}
