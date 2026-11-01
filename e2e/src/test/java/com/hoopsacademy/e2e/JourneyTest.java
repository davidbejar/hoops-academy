package com.hoopsacademy.e2e;

import static com.hoopsacademy.e2e.support.Check.id;
import static com.hoopsacademy.e2e.support.Check.status;
import static com.hoopsacademy.e2e.support.Json.of;
import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.hoopsacademy.e2e.support.Actor;
import com.hoopsacademy.e2e.support.E2eEnv;
import com.hoopsacademy.e2e.support.KeycloakAdmin;
import com.hoopsacademy.e2e.support.KeycloakUserTokens;
import com.hoopsacademy.e2e.support.MailHog;
import io.restassured.response.Response;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.extension.ConditionEvaluationResult;
import org.junit.jupiter.api.extension.ExecutionCondition;
import org.junit.jupiter.api.extension.ExtensionContext;
import org.junit.jupiter.api.extension.RegisterExtension;
import org.junit.jupiter.api.extension.TestWatcher;

/**
 * The ordered end-to-end journey of two academies against a running stack (see docs/runbooks/e2e.md). Each step
 * builds on the state of the previous ones (fields), so a failing step makes the later ones fail too: read the first
 * failure. All data is unique per run (timestamp suffix), so the suite can run repeatedly on the same stack.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class JourneyTest {

    /** Later steps depend on earlier ones: once a step failed, the rest is skipped so the first failure is the signal. */
    private static boolean failed;

    @RegisterExtension
    static final FailFast STOP_AFTER_FIRST_FAILURE = new FailFast();

    static final class FailFast implements ExecutionCondition, TestWatcher {
        @Override
        public ConditionEvaluationResult evaluateExecutionCondition(ExtensionContext ctx) {
            return failed && ctx.getTestMethod().isPresent()
                    ? ConditionEvaluationResult.disabled("an earlier journey step failed")
                    : ConditionEvaluationResult.enabled("ok");
        }

        @Override
        public void testFailed(ExtensionContext context, Throwable cause) {
            failed = true;
        }
    }

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    private final String run = Long.toString(System.currentTimeMillis(), 36);
    private final LocalDate today = LocalDate.now(ZONE);
    private final KeycloakUserTokens tokens = new KeycloakUserTokens();
    private final KeycloakAdmin keycloakAdmin = new KeycloakAdmin();
    private final MailHog mail = new MailHog();
    /** Random per run, >= 12 chars (realm password policy); only ever sent to Keycloak. */
    private final String password = "E2e-" + UUID.randomUUID() + "-" + run;

    private Actor superAdmin;
    // tenant A
    private UUID tenantA;
    private String adminEmail;
    private Actor admin;
    private UUID seasonId;
    private Map<String, UUID> categoryByCode = new java.util.HashMap<>();
    private int categoryMaxAge;
    private UUID teamId;
    private UUID coachPersonId;
    private UUID parentPersonId;
    private Actor coach;
    private Actor parent;
    private UUID playerA; // linked to the parent, created by the admin
    private UUID playerB; // requested by the coach, approved by the admin
    private UUID matchId;
    private UUID orphanPlayer;
    private final List<Map<String, Object>> sentEvents = new ArrayList<>();
    private List<Integer> firstServerSeqs;
    private UUID sessionId;
    private UUID injuryId;
    private UUID season2;
    private UUID caseId;
    // tenant B
    private UUID tenantB;
    private Actor adminB;

    @BeforeAll
    void enabled() {
        assumeTrue(E2eEnv.enabled(), "set -De2e.baseUrl=http://localhost:8080 (or E2E_BASE_URL) to run the journeys");
        if ("1".equals(System.getenv("E2E_FIX_REALM")) && keycloakAdmin.ensureWebClientHasBasicScope()) {
            System.out.println("[e2e] E2E_FIX_REALM: added scope 'basic' to realm client 'web' (WP18 bug 1)");
        }
    }

    private Actor signIn(String label, String email, UUID tenant) {
        keycloakAdmin.setPassword(email, password);
        String token = tokens.login(email, password);
        if (!KeycloakUserTokens.hasSub(token)) {
            throw new IllegalStateException("the access token of " + label + " has no 'sub' claim: realm client 'web' lacks the "
                    + "'basic' client scope (docs/wp/WP18-e2e.md bug 1). Fix infra/keycloak/realm-academy.json (add \"basic\" to "
                    + "defaultClientScopes) and reset the realm, or run with E2E_FIX_REALM=1 to patch the running realm.");
        }
        return new Actor(label, token, tenant);
    }

    private String email(String who) {
        return "e2e-" + run + "-" + who + "@hoops.local";
    }

    // ------------------------------------------------------------------------------------------ platform

    @Test
    @Order(1)
    void superAdminCreatesTenantWithFirstAdmin() {
        superAdmin = new Actor("superadmin", tokens.login("superadmin", E2eEnv.required("DEV_USER_PASSWORD")), null);
        adminEmail = email("admin");
        Response r = status(superAdmin.post("/platform/tenants", of(
                "slug", "e2e-" + run, "name", "E2E Academy " + run, "timezone", "Europe/Madrid", "defaultLocale", "en",
                "firstAdmin", of("email", adminEmail, "givenName", "Ada", "familyName", "Admin"))), 201);
        tenantA = id(r, "id");
        assertEquals("ACTIVE", r.jsonPath().getString("status"));
    }

    @Test
    @Order(2)
    void setupEmailArrivesInMailHog() {
        assumeTrue(mail.reachable(), "MailHog not reachable at " + E2eEnv.mailhogUrl() + " (set E2E_MAILHOG_URL)");
        var msg = await().atMost(Duration.ofSeconds(30)).pollInterval(Duration.ofSeconds(1))
                .until(() -> mail.latestTo(adminEmail), java.util.Optional::isPresent).orElseThrow();
        assertFalse(msg.get("Content").get("Body").asText().isBlank(), "setup e-mail has a body");
        // the link needs a browser; the suite sets the password through the Keycloak Admin API instead (KeycloakAdmin)
    }

    @Test
    @Order(3)
    void adminLogsInAndSeesTheTenant() {
        admin = signIn("admin", adminEmail, tenantA);
        Response me = status(admin.inTenant(null).get("/api/core/me"), 200);
        assertThat(me.jsonPath().getList("memberships.tenant.id")).contains(tenantA.toString());
        assertThat(me.jsonPath().getList("memberships.find { it.tenant.id == '" + tenantA + "' }.roles")).contains("ADMIN");
        status(admin.get("/api/core/tenant"), 200);
    }

    // ------------------------------------------------------------------------------------------ roster

    @Test
    @Order(4)
    void adminCreatesSeasonCategoriesAndTeam() {
        Response cats = status(admin.get("/api/core/age-categories"), 200);
        List<Map<String, Object>> list = cats.jsonPath().getList("$");
        assertThat(list).extracting(m -> m.get("code")).contains("U8", "U14", "SENIOR");
        for (Map<String, Object> c : list) {
            categoryByCode.put((String) c.get("code"), UUID.fromString((String) c.get("id")));
        }
        categoryMaxAge = ((Number) list.stream().filter(c -> "U14".equals(c.get("code"))).findFirst().orElseThrow().get("maxAge")).intValue();

        Response s = status(admin.post("/api/core/seasons", of(
                "name", "E2E " + run, "startsOn", today.minusDays(100).toString(), "endsOn", today.plusDays(250).toString(),
                "referenceYear", today.getYear())), 201);
        seasonId = id(s, "id");
        Response t = status(admin.post("/api/core/teams", of(
                "seasonId", seasonId, "name", "U14 Wolves " + run, "ageCategoryId", categoryByCode.get("U14"),
                "genderPolicy", "MIXED")), 201);
        teamId = id(t, "id");
    }

    @Test
    @Order(5)
    void adminInvitesCoachAndParentAndStaffsTheTeam() {
        Response c = status(admin.post("/api/core/members", of(
                "givenName", "Carla", "familyName", "Coach", "email", email("coach"), "roles", List.of("COACH"))), 201);
        coachPersonId = id(c, "personId");
        Response p = status(admin.post("/api/core/members", of(
                "givenName", "Paco", "familyName", "Parent", "email", email("parent"), "roles", List.of("PARENT"))), 201);
        parentPersonId = id(p, "personId");
        status(admin.put("/api/core/teams/" + teamId + "/staff/" + coachPersonId, of("role", "COACH")), 200);

        coach = signIn("coach", email("coach"), tenantA);
        parent = signIn("parent", email("parent"), tenantA);
        Response me = status(coach.inTenant(null).get("/api/core/me"), 200);
        assertThat(me.jsonPath().getList("memberships[0].authz.staffTeamIds")).contains(teamId.toString());
    }

    @Test
    @Order(6)
    void adminAddsPlayerAndCoachRequestsOneWhichTheAdminApproves() {
        int by = today.getYear() - (categoryMaxAge - 1);
        Response a = status(admin.post("/api/core/players", of(
                "givenName", "Alex", "familyName", "Alpha", "birthDate", by + "-03-15", "gender", "MALE",
                "teamId", teamId, "jerseyNumber", "7")), 201);
        playerA = id(a, "player.id");
        assertEquals("ACTIVE", a.jsonPath().getString("player.status"));

        // coach: pending request (202), invisible effects until approved
        Response b = status(coach.post("/api/core/players", of(
                "givenName", "Bea", "familyName", "Bravo", "birthDate", by + "-07-01", "gender", "FEMALE",
                "teamId", teamId, "jerseyNumber", "10", "note", "tryout went well")), 202);
        playerB = id(b, "player.id");
        UUID requestId = id(b, "approvalRequest.id");
        assertEquals("PENDING_APPROVAL", b.jsonPath().getString("player.status"));
        assertEquals("PENDING", b.jsonPath().getString("approvalRequest.status"));
        // the coach may not decide their own request
        status(coach.post("/api/core/approval-requests/" + requestId + "/approve", of()), 403);

        Response pending = status(admin.get("/api/core/approval-requests?status=PENDING&action=ADD_PLAYER"), 200);
        assertThat(pending.jsonPath().getList("items.id")).contains(requestId.toString());
        Response approved = status(admin.post("/api/core/approval-requests/" + requestId + "/approve", of("note", "welcome")), 200);
        assertEquals("APPROVED", approved.jsonPath().getString("status"));

        Response roster = status(admin.get("/api/core/teams/" + teamId + "/players"), 200);
        assertThat(roster.jsonPath().getList("player.id")).contains(playerA.toString(), playerB.toString());
        assertEquals("ACTIVE", status(admin.get("/api/core/players/" + playerB), 200).jsonPath().getString("status"));
    }

    @Test
    @Order(7)
    void guardianLinkMakesTheParentSeeOnlyTheLinkedChild() {
        status(admin.post("/api/core/guardian-links", of("guardianPersonId", parentPersonId, "playerId", playerA)), 201);
        Response players = status(parent.get("/api/core/players"), 200);
        assertThat(players.jsonPath().getList("items.id")).containsExactly(playerA.toString());
        status(parent.get("/api/core/players/" + playerB), 404);
        Response me = status(parent.inTenant(null).get("/api/core/me"), 200);
        assertThat(me.jsonPath().getList("memberships[0].authz.linkedPlayerIds")).containsExactly(playerA.toString());
    }

    // ------------------------------------------------------------------------------------------ matches

    @Test
    @Order(10)
    void coachCreatesMatchSetsRosterAndStarts() {
        Response m = status(coach.post("/api/game/matches", of(
                "teamId", teamId, "opponentName", "Rivals " + run, "homeAway", "HOME",
                "scheduledAt", Instant.now().plusSeconds(3600).toString(), "venue", "Main court")), 201);
        matchId = id(m, "id");
        assertEquals("SCHEDULED", m.jsonPath().getString("status"));
        status(coach.post("/api/game/matches/" + matchId + "/start"), 422); // no starters yet
        status(coach.put("/api/game/matches/" + matchId + "/roster", of("entries", List.of(
                of("playerId", playerA, "jerseyNumber", "7", "isStarter", true),
                of("playerId", playerB, "jerseyNumber", "10", "isStarter", true)))), 200);
        Response started = status(coach.post("/api/game/matches/" + matchId + "/start"), 200);
        assertEquals("LIVE", started.jsonPath().getString("status"));
        // a parent may not manage the match
        status(parent.post("/api/game/matches/" + matchId + "/finish"), 403);
    }

    @Test
    @Order(11)
    void coachAndParentEnterEventsAndTheParentIsRestricted() {
        // coach device: 2PT made + 2PT missed by A, 3PT made + assist by B, defensive rebound A, opponent 2 points
        List<Map<String, Object>> coachEvents = List.of(
                event("coach-dev", 1, "PERIOD_START", 1, 600, null, null),
                event("coach-dev", 2, "SHOT", 1, 580, playerA, of("points", 2, "made", true)),
                event("coach-dev", 3, "SHOT", 1, 560, playerA, of("points", 2, "made", false)),
                event("coach-dev", 4, "SHOT", 1, 540, playerB, of("points", 3, "made", true)),
                event("coach-dev", 5, "ASSIST", 1, 540, playerA, null),
                event("coach-dev", 6, "REBOUND", 1, 520, playerA, of("kind", "DEFENSIVE")),
                event("coach-dev", 7, "OPPONENT_SCORE", 1, 500, null, of("points", 2)),
                event("coach-dev", 8, "PERIOD_END", 1, 0, null, null));
        Response cr = status(coach.post("/api/game/matches/" + matchId + "/events:batch", of("events", coachEvents)), 200);
        assertThat(cr.jsonPath().getList("results.status")).containsOnly("ACCEPTED");
        sentEvents.addAll(coachEvents);
        firstServerSeqs = cr.jsonPath().getList("results.serverSeq");

        // parent device: free throw for the linked child accepted; other child's shot and PERIOD_START rejected
        Map<String, Object> ok = event("parent-dev", 1, "SHOT", 2, 590, playerA, of("points", 1, "made", true));
        Map<String, Object> other = event("parent-dev", 2, "SHOT", 2, 580, playerB, of("points", 2, "made", true));
        Map<String, Object> period = event("parent-dev", 3, "PERIOD_START", 2, 600, null, null);
        Response pr = status(parent.post("/api/game/matches/" + matchId + "/events:batch", of("events", List.of(ok, other, period))), 200);
        assertEquals(List.of("ACCEPTED", "REJECTED", "REJECTED"), pr.jsonPath().getList("results.status"));
        assertEquals(List.of("NOT_AUTHORIZED", "NOT_AUTHORIZED"), pr.jsonPath().getList("results.findAll { it.status == 'REJECTED' }.reason"));
        sentEvents.add(ok);
        firstServerSeqs = new ArrayList<>(firstServerSeqs);
        firstServerSeqs.add(pr.jsonPath().getInt("results[0].serverSeq"));
    }

    @Test
    @Order(12)
    void replayingTheCoachBatchIsIdempotent() {
        List<Map<String, Object>> coachEvents = sentEvents.subList(0, 8);
        Response again = status(coach.post("/api/game/matches/" + matchId + "/events:batch", of("events", coachEvents)), 200);
        assertThat(again.jsonPath().getList("results.status")).containsOnly("DUPLICATE");
        assertEquals(firstServerSeqs.subList(0, 8), again.jsonPath().getList("results.serverSeq"));
        Response feed = status(admin.get("/api/game/matches/" + matchId + "/events"), 200);
        assertEquals(9, feed.jsonPath().getList("events").size(), "8 coach events + 1 accepted parent event, no duplicates stored");
    }

    @Test
    @Order(13)
    void boxScoreIsConsistentAndFinishingAndSeasonStatsFollow() {
        Response box = status(admin.get("/api/game/matches/" + matchId + "/box-score"), 200);
        // A: 2 (made) + 1 (parent free throw); B: 3; opponent 2
        assertEquals(6, box.jsonPath().getInt("score.team"));
        assertEquals(2, box.jsonPath().getInt("score.opponent"));
        assertEquals(6, box.jsonPath().getInt("teamTotals.points"));
        assertEquals(3, box.jsonPath().getInt("players.find { it.playerId == '" + playerA + "' }.stats.points"));
        assertEquals(1, box.jsonPath().getInt("players.find { it.playerId == '" + playerA + "' }.stats.assists"));
        assertEquals(2, box.jsonPath().getInt("players.find { it.playerId == '" + playerA + "' }.stats.fg2Attempted"));
        assertEquals(1, box.jsonPath().getInt("players.find { it.playerId == '" + playerA + "' }.stats.defensiveRebounds"));
        assertEquals(3, box.jsonPath().getInt("players.find { it.playerId == '" + playerB + "' }.stats.points"));
        int sum = box.jsonPath().getList("players.stats.points", Integer.class).stream().mapToInt(Integer::intValue).sum();
        assertEquals(box.jsonPath().getInt("teamTotals.points"), sum, "team total equals the sum of the player lines");
        // the parent sees the linked child's line only
        Response pbox = status(parent.get("/api/game/matches/" + matchId + "/box-score"), 200);
        assertThat(pbox.jsonPath().getList("players.playerId")).containsExactly(playerA.toString());

        Response fin = status(coach.post("/api/game/matches/" + matchId + "/finish"), 200);
        assertEquals("FINISHED", fin.jsonPath().getString("status"));
        assertEquals(6, fin.jsonPath().getInt("score.team"));
        Response stats = status(admin.get("/api/game/players/" + playerA + "/season-stats?seasonId=" + seasonId), 200);
        assertEquals(1, stats.jsonPath().getInt("gamesStarted"));
        assertThat(stats.jsonPath().getList("matches")).hasSize(1);
        assertEquals(3, stats.jsonPath().getInt("totals.points"));
        status(parent.get("/api/game/players/" + playerB + "/season-stats?seasonId=" + seasonId), 404);
    }

    // ------------------------------------------------------------------------------------------ training

    @Test
    @Order(20)
    void scheduleMaterialisesSessionsAndAttendanceHonoursPlannedAbsence() {
        Response sch = status(coach.post("/api/athlete/training-schedules", of(
                "teamId", teamId, "dayOfWeek", today.getDayOfWeek().name(), "startTime", "18:00", "durationMinutes", 90,
                "location", "Gym 1", "validFrom", today.toString())), 201);
        UUID scheduleId = id(sch, "id");
        Response sessions = await().atMost(Duration.ofSeconds(20)).pollInterval(Duration.ofSeconds(1)).until(
                () -> coach.get("/api/athlete/training-sessions?teamId=" + teamId + "&from=" + today + "&to=" + today.plusWeeks(2)),
                r -> r.statusCode() == 200 && !r.jsonPath().getList("items").isEmpty());
        assertThat(sessions.jsonPath().getList("items.scheduleId")).contains(scheduleId.toString());
        assertThat(sessions.jsonPath().getList("items").size()).isBetween(1, 3);
        sessionId = UUID.fromString(sessions.jsonPath().getString("items[0].id"));

        // the parent announces the child's absence on the first session day
        String day = sessions.jsonPath().getString("items[0].startsAt").substring(0, 10);
        status(parent.post("/api/athlete/planned-absences", of("playerId", playerA, "fromDate", day, "toDate", day, "reason", "family trip")), 201);
        Response sheet = status(coach.get("/api/athlete/training-sessions/" + sessionId + "/attendance"), 200);
        assertEquals(true, sheet.jsonPath().getBoolean("entries.find { it.playerId == '" + playerA + "' }.expectedAbsent"));
        assertEquals(false, sheet.jsonPath().getBoolean("entries.find { it.playerId == '" + playerB + "' }.expectedAbsent"));

        Response rec = status(coach.put("/api/athlete/training-sessions/" + sessionId + "/attendance", of("entries", List.of(
                of("playerId", playerA, "status", "EXCUSED"),
                of("playerId", playerB, "status", "LATE", "minutesLate", 7)))), 200);
        assertEquals("EXCUSED", rec.jsonPath().getString("entries.find { it.playerId == '" + playerA + "' }.status"));
        assertEquals("LATE", rec.jsonPath().getString("entries.find { it.playerId == '" + playerB + "' }.status"));
    }

    @Test
    @Order(21)
    void planCopyOnUseAssignmentAndCompletion() {
        Response templates = status(coach.get("/api/athlete/training-plans?template=true"), 200);
        assertFalse(templates.jsonPath().getList("items").isEmpty(), "global plan templates are seeded");
        UUID templateId = UUID.fromString(templates.jsonPath().getString("items[0].id"));
        status(coach.patch("/api/athlete/training-plans/" + templateId, of("name", "hijack")), 403); // PLAN_IS_TEMPLATE
        Response copy = status(coach.post("/api/athlete/training-plans/" + templateId + ":copy", of("name", "Copy " + run)), 201);
        UUID planId = id(copy, "id");
        assertEquals(false, copy.jsonPath().getBoolean("template"));
        assertEquals(templateId.toString(), copy.jsonPath().getString("sourceTemplateId"));

        Response asg = status(coach.post("/api/athlete/plan-assignments", of(
                "planId", planId, "teamId", teamId, "dueOn", today.plusDays(7).toString(), "notes", "before the next game")), 201);
        UUID assignmentId = id(asg, "id");
        status(parent.put("/api/athlete/plan-assignments/" + assignmentId + "/completions/" + playerA, of("status", "DONE", "comment", "did it")), 200);
        Response progress = status(coach.get("/api/athlete/plan-assignments/" + assignmentId + "/progress"), 200);
        assertEquals(2, progress.jsonPath().getInt("total"));
        assertEquals(1, progress.jsonPath().getInt("counts.DONE"));
        assertEquals(1, progress.jsonPath().getInt("notRecorded"));
    }

    @Test
    @Order(22)
    void injuryMakesPlayerUnavailableThenMeasurementAndPhysicalTestWithBand() {
        Response inj = status(coach.post("/api/athlete/injuries", of(
                "playerId", playerA, "occurredOn", today.toString(), "bodyPart", "left ankle", "severity", "MODERATE",
                "expectedReturnOn", today.plusDays(14).toString())), 201);
        injuryId = id(inj, "id");
        Response av = status(admin.get("/api/athlete/players/" + playerA + "/availability"), 200);
        assertFalse(av.jsonPath().getBoolean("available"));
        assertEquals(today.plusDays(14).toString(), av.jsonPath().getString("expectedReturnOn"));
        assertTrue(status(admin.get("/api/athlete/players/" + playerB + "/availability"), 200).jsonPath().getBoolean("available"));

        status(coach.post("/api/athlete/body-measurements", of(
                "playerId", playerA, "measuredOn", today.toString(), "heightCm", 168.5, "weightKg", 55.2)), 201);

        Response types = status(coach.get("/api/athlete/physical-test-types"), 200);
        UUID jump = UUID.fromString(types.jsonPath().getString("find { it.code == 'VERTICAL_JUMP' }.id"));
        Response res = status(coach.post("/api/athlete/physical-test-results", of(
                "playerId", playerA, "testTypeId", jump, "measuredOn", today.toString(), "value", 35.0)), 201);
        assertEquals("MATCHED", res.jsonPath().getString("bandStatus"));
        assertNotNull(res.jsonPath().getString("expectedBand"), "a norm band is resolved from the player's age and gender");
        LocalDate born = LocalDate.of(today.getYear() - (categoryMaxAge - 1), 3, 15);
        assertEquals(java.time.Period.between(born, today).getYears(), res.jsonPath().getInt("ageAtMeasurement"),
                "age is in full years at the measurement date");
    }

    // ------------------------------------------------------------------------------------------ platform stats

    @Test
    @Order(30)
    void platformUsageShowsTheCounts() {
        Response u = status(superAdmin.get("/platform/tenants/" + tenantA + "/usage"), 200);
        assertThat(u.jsonPath().getList("unavailableServices")).isEmpty();
        Map<String, Integer> core = counters(u, "core");
        Map<String, Integer> game = counters(u, "game");
        Map<String, Integer> athlete = counters(u, "athlete");
        assertThat(core.get("members")).isGreaterThanOrEqualTo(3);
        assertThat(core.get("players")).isGreaterThanOrEqualTo(2);
        assertEquals(1, core.get("teams"));
        assertEquals(1, game.get("matches"));
        assertEquals(1, game.get("finishedMatches"));
        assertEquals(9, game.get("matchEvents"));
        assertEquals(1, athlete.get("trainingSchedules"));
        assertEquals(1, athlete.get("injuries"));
        assertEquals(1, athlete.get("bodyMeasurements"));
        assertEquals(1, athlete.get("physicalTestResults"));
        assertEquals(1, athlete.get("plannedAbsences"));
        // tenants never see platform statistics
        status(admin.get("/platform/tenants/" + tenantA + "/usage"), 403);
    }

    private Map<String, Integer> counters(Response usage, String service) {
        return usage.jsonPath().getMap("services.find { it.service == '" + service + "' }.counters");
    }

    // ------------------------------------------------------------------------------------------ rollover

    @Test
    @Order(40)
    void rolloverIntoTheNextSeasonProducesAnOrphanWhichIsResolved() {
        // an over-age player for the next season: eligible now (age = max), too old next year
        int oldBy = today.getYear() - categoryMaxAge;
        Response c = status(admin.post("/api/core/players", of(
                "givenName", "Otto", "familyName", "Older", "birthDate", oldBy + "-01-10", "gender", "MALE",
                "teamId", teamId, "jerseyNumber", "99")), 201);
        orphanPlayer = id(c, "player.id");

        Response s2 = status(admin.post("/api/core/seasons", of(
                "name", "E2E next " + run, "startsOn", today.plusDays(251).toString(), "endsOn", today.plusDays(600).toString(),
                "referenceYear", today.getYear() + 1)), 201);
        season2 = id(s2, "id");
        Response roll = status(admin.post("/api/core/seasons/" + season2 + "/rollover", of(
                "fromSeasonId", seasonId, "cloneStaff", true, "clonePlayers", true)), 200);
        assertThat(roll.jsonPath().getList("clonedTeams")).hasSize(1);
        assertThat(roll.jsonPath().getList("orphans.player.id")).containsExactly(orphanPlayer.toString());
        assertThat(roll.jsonPath().getList("orphans[0].reasons")).contains("CATEGORY_TOO_LOW");
        assertThat(roll.jsonPath().getList("openedCaseIds")).hasSize(1);
        caseId = UUID.fromString(roll.jsonPath().getString("openedCaseIds[0]"));

        Response orphans = status(admin.get("/api/core/players?status=ORPHAN"), 200);
        assertThat(orphans.jsonPath().getList("items.id")).containsExactly(orphanPlayer.toString());
    }

    @Test
    @Order(41)
    void eligibilityCaseIsResolved() {
        Response open = status(admin.get("/api/core/eligibility-cases?status=OPEN"), 200);
        assertThat(open.jsonPath().getList("items.id")).contains(caseId.toString());
        status(parent.post("/api/core/eligibility-cases/" + caseId + "/resolve", of("resolution", "DISMISSED")), 403);
        Response done = status(admin.post("/api/core/eligibility-cases/" + caseId + "/resolve", of(
                "resolution", "REMOVED_FROM_TEAM", "note", "moves up to the senior group")), 200);
        assertEquals("RESOLVED", done.jsonPath().getString("status"));
        assertEquals("REMOVED_FROM_TEAM", done.jsonPath().getString("resolution"));
        status(admin.post("/api/core/eligibility-cases/" + caseId + "/resolve", of("resolution", "DISMISSED")), 409);
    }

    // ------------------------------------------------------------------------------------------ isolation

    @Test
    @Order(50)
    void secondTenantCannotSeeTheFirstTenantsData() {
        String emailB = email("adminb");
        Response t = status(superAdmin.post("/platform/tenants", of(
                "slug", "e2e-b-" + run, "name", "E2E Other " + run, "timezone", "Europe/Madrid", "defaultLocale", "es",
                "firstAdmin", of("email", emailB, "givenName", "Berta", "familyName", "Boss"))), 201);
        tenantB = id(t, "id");
        adminB = signIn("adminB", emailB, tenantB);
        status(adminB.get("/api/core/tenant"), 200);

        // by id inside B's tenant: not found (never 403, never data)
        status(adminB.get("/api/core/teams/" + teamId), 404);
        status(adminB.get("/api/core/players/" + playerA), 404);
        status(adminB.get("/api/game/matches/" + matchId), 404);
        status(adminB.get("/api/game/matches/" + matchId + "/box-score"), 404);
        status(adminB.get("/api/athlete/training-sessions/" + sessionId), 404);
        status(adminB.get("/api/athlete/injuries/" + injuryId), 404);
        // lists are empty
        assertThat(adminB.get("/api/core/teams").jsonPath().getList("items")).isEmpty();
        assertThat(adminB.get("/api/game/matches").jsonPath().getList("items")).isEmpty();
        // B's admin naming A's tenant in the header is a non-member: 404 on every service
        Actor intruder = adminB.inTenant(tenantA);
        status(intruder.get("/api/core/teams/" + teamId), 404);
        status(intruder.get("/api/game/matches/" + matchId), 404);
        status(intruder.get("/api/athlete/training-sessions/" + sessionId), 404);
        // and A's people cannot reach B
        status(admin.inTenant(tenantB).get("/api/core/tenant"), 404);
        status(coach.inTenant(tenantB).get("/api/game/matches"), 404);
    }

    @Test
    @Order(51)
    void internalEndpointsAreBlockedAtTheGateway() {
        String svc = tokens.serviceToken("core-service", "CORE_SERVICE_CLIENT_SECRET");
        for (String path : List.of("/internal/usage/" + tenantA, "/internal/teams/" + teamId + "/roster",
                "/internal/authz/" + tenantA + "/x", "/internal/players:batch")) {
            assertEquals(403, io.restassured.RestAssured.given().baseUri(E2eEnv.baseUrl()).auth().oauth2(svc)
                    .get(path).statusCode(), path + " with a valid service token");
            assertEquals(403, io.restassured.RestAssured.given().baseUri(E2eEnv.baseUrl()).get(path).statusCode(),
                    path + " anonymous");
        }
        // a user token and the per-service prefixes expose nothing either
        assertThat(io.restassured.RestAssured.given().baseUri(E2eEnv.baseUrl()).auth().oauth2("x")
                .get("/api/core/internal/usage/" + tenantA).statusCode()).isNotEqualTo(200);
        assertEquals(401, io.restassured.RestAssured.given().baseUri(E2eEnv.baseUrl()).get("/api/core/teams").statusCode());
    }

    // ------------------------------------------------------------------------------------------ lifecycle

    @Test
    @Order(60)
    void suspendedTenantAnswersNotFoundForItsMembersAndReactivationRestoresIt() {
        status(superAdmin.post("/platform/tenants/" + tenantA + "/suspend", of("reason", "e2e: unpaid invoice")), 200);
        // core drops its caches on the write; game and athlete cache the membership for up to 30 s
        await().atMost(Duration.ofSeconds(60)).pollInterval(Duration.ofSeconds(2)).untilAsserted(() -> {
            assertEquals(404, admin.get("/api/core/teams").statusCode());
            assertEquals(404, coach.getUnvalidated("/api/game/matches").statusCode());
            assertEquals(404, parent.getUnvalidated("/api/athlete/training-sessions?teamId=" + teamId).statusCode());
        });
        status(admin.get("/api/core/tenant"), 404);
        Response me = status(admin.inTenant(null).get("/api/core/me"), 200);
        assertThat(me.jsonPath().getList("memberships.tenant.id")).doesNotContain(tenantA.toString());
        // the other tenant is unaffected
        status(adminB.get("/api/core/tenant"), 200);

        status(superAdmin.post("/platform/tenants/" + tenantA + "/reactivate"), 200);
        await().atMost(Duration.ofSeconds(60)).pollInterval(Duration.ofSeconds(2)).untilAsserted(() -> {
            assertEquals(200, admin.get("/api/core/teams").statusCode());
            assertEquals(200, coach.get("/api/game/matches").statusCode());
            assertEquals(200, parent.get("/api/athlete/training-sessions?teamId=" + teamId).statusCode());
        });
    }

    // ------------------------------------------------------------------------------------------ helpers

    /** A match event as the API expects it; {@code payload} and {@code player} are optional. */
    private Map<String, Object> event(String device, int seq, String type, int period, int clock, UUID player, Map<String, Object> payload) {
        Map<String, Object> e = new java.util.LinkedHashMap<>();
        e.put("id", UUID.randomUUID().toString());
        e.put("deviceId", device);
        e.put("clientSeq", seq);
        e.put("type", type);
        e.put("period", period);
        e.put("clockSecondsRemaining", clock);
        e.put("recordedAtClient", Instant.now().toString());
        if (player != null) {
            e.put("playerId", player.toString());
        }
        if (payload != null) {
            e.put("payload", payload);
        }
        return e;
    }
}
