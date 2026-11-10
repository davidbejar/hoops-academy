package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.adapters.in.rest.ExerciseApiTest.EXERCISES;
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
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static com.hoopsacademy.athlete.support.ApiSupport.unvalidated;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.Caller;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * docs/domain/authz-matrix.md for the exercise catalogue: whoever manages plans manages the academy's exercises and adds
 * them to plans (ADMIN, COACH, ASSISTANT_COACH, whatever team); everyone who reads plans reads exercises. 2xx = allowed,
 * 403 = member without the right.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class ExerciseRoleMatrixTest {

    static final String TENANT = "92000000-0000-4000-8000-000000000021";

    String exercise;
    String plan;

    @BeforeEach
    void setUp() {
        act(ADMIN);
        exercise = ExerciseApiTest.create(TENANT, Map.of("title", "Matrix exercise"));
        plan = unvalidated(TENANT).body(Map.of("name", "Matrix plan")).post("/api/athlete/training-plans")
                .then().statusCode(201).extract().path("id");
    }

    private static void act(Caller c) {
        member(TENANT, c.roles(), c.staffTeams(), c.linked(), c.own());
    }

    static Stream<Arguments> write() {
        return Stream.of(
                Arguments.of(ADMIN, true), Arguments.of(COACH_OF_TEAM, true), Arguments.of(ASSISTANT_OF_TEAM, true),
                Arguments.of(COACH_OF_OTHER, true), Arguments.of(PARENT_LINKED, false), Arguments.of(PLAYER_SELF, false),
                Arguments.of(COACH_AND_PARENT, true), Arguments.of(ADMIN_AND_PLAYER, true), Arguments.of(NO_ROLE, false));
    }

    static Stream<Arguments> read() {
        return Stream.of(Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(PARENT_LINKED, 200),
                Arguments.of(PARENT_UNLINKED, 200), Arguments.of(PLAYER_SELF, 200), Arguments.of(PLAYER_OTHER, 200),
                Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "create exercise: {0} -> {1}")
    @MethodSource("write")
    void createExercise(Caller caller, boolean allowed) {
        act(caller);

        assertThat(unvalidated(TENANT).body(Map.of("title", "E")).post(EXERCISES).then().extract().statusCode())
                .isEqualTo(allowed ? 201 : 403);
    }

    @ParameterizedTest(name = "update exercise: {0} -> {1}")
    @MethodSource("write")
    void updateExercise(Caller caller, boolean allowed) {
        act(caller);

        assertThat(unvalidated(TENANT).body(Map.of("title", "Renamed")).patch(EXERCISES + "/" + exercise).then()
                .extract().statusCode()).isEqualTo(allowed ? 200 : 403);
    }

    @ParameterizedTest(name = "archive and unarchive exercise: {0} -> {1}")
    @MethodSource("write")
    void archiveExercise(Caller caller, boolean allowed) {
        act(caller);

        for (String action : List.of(":archive", ":unarchive")) {
            assertThat(unvalidated(TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + exercise + action).then()
                    .extract().statusCode()).as(action).isEqualTo(allowed ? 200 : 403);
        }
    }

    @ParameterizedTest(name = "add exercise to a plan: {0} -> {1}")
    @MethodSource("write")
    void addExerciseToPlan(Caller caller, boolean allowed) {
        act(caller);

        assertThat(unvalidated(TENANT).urlEncodingEnabled(false)
                .body(Map.of("items", List.of(Map.of("exerciseId", exercise))))
                .post("/api/athlete/training-plans/" + plan + "/items:copy").then().extract().statusCode())
                .isEqualTo(allowed ? 200 : 403);
    }

    @ParameterizedTest(name = "read exercises: {0} -> {1}")
    @MethodSource("read")
    void readExercises(Caller caller, int expected) {
        act(caller);

        assertThat(unvalidated(TENANT).get(EXERCISES).then().extract().statusCode()).isEqualTo(expected);
        assertThat(unvalidated(TENANT).get(EXERCISES + "/" + exercise).then().extract().statusCode()).isEqualTo(expected);
    }
}
