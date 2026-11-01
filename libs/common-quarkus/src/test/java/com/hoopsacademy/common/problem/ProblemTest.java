package com.hoopsacademy.common.problem;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.ws.rs.core.Response;
import java.util.List;
import org.jboss.logging.MDC;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class ProblemTest {

    @AfterEach
    void clearMdc() {
        MDC.remove("traceId");
    }

    @Test
    void buildsProblemFromTypeWithoutTraceWhenNoTelemetryContext() {
        Problem problem = Problem.of(ProblemType.NOT_FOUND, "Widget not found", "/api/core/widgets/1");

        assertThat(problem.type()).isEqualTo("urn:hoops:problem:not-found");
        assertThat(problem.title()).isEqualTo("Not Found");
        assertThat(problem.status()).isEqualTo(404);
        assertThat(problem.detail()).isEqualTo("Widget not found");
        assertThat(problem.instance()).isEqualTo("/api/core/widgets/1");
        assertThat(problem.traceId()).isNull();
        assertThat(problem.violations()).isNull();
        assertThat(problem.code()).isNull();
    }

    @Test
    void carriesAnOptionalMachineReadableCodeAndReasons() {
        var reason = new Problem.Violation("birthDate", "MISSING_BIRTH_DATE", "Birth date is required");

        Problem problem = Problem.of(ProblemType.DOMAIN_RULE_VIOLATION, "Not eligible", "/a", "PLAYER_INELIGIBLE", List.of(reason));

        assertThat(problem.code()).isEqualTo("PLAYER_INELIGIBLE");
        assertThat(problem.violations()).containsExactly(reason);
    }

    @Test
    void omitsAbsentViolationMembers() throws Exception {
        String json = new ObjectMapper().writeValueAsString(new Problem.Violation("name", "must not be blank"));

        assertThat(json).isEqualTo("{\"field\":\"name\",\"message\":\"must not be blank\"}");
    }

    @Test
    void picksUpTraceIdFromLoggingContext() {
        MDC.put("traceId", "4bf92f3577b34da6a3ce929d0e0e4736");

        assertThat(Problem.of(ProblemType.CONFLICT, null, "/x").traceId()).isEqualTo("4bf92f3577b34da6a3ce929d0e0e4736");
    }

    @Test
    void genericStatusUsesAboutBlankAndReasonPhrase() {
        Problem problem = Problem.ofStatus(405, "/api/x");

        assertThat(problem.type()).isEqualTo("about:blank");
        assertThat(problem.title()).isEqualTo("Method Not Allowed");
        assertThat(problem.status()).isEqualTo(405);
        assertThat(problem.detail()).isNull();
    }

    @Test
    void genericStatusFallsBackToTitleForUnknownCodes() {
        assertThat(Problem.ofStatus(499, "/x").title()).isEqualTo("HTTP 499");
    }

    @Test
    void serializesOnlyPresentFields() throws Exception {
        String json = new ObjectMapper().writeValueAsString(Problem.of(ProblemType.FORBIDDEN, null, "/a"));

        assertThat(json).doesNotContain("detail", "traceId", "violations", "code").contains("\"status\":403");
    }

    @Test
    void validationProblemCarriesViolations() {
        Problem problem = Problem.validation(List.of(new Problem.Violation("name", "must not be blank")), "/a");

        assertThat(problem.status()).isEqualTo(400);
        assertThat(problem.type()).isEqualTo("urn:hoops:problem:validation");
        assertThat(problem.violations()).containsExactly(new Problem.Violation("name", "must not be blank"));
    }

    @Test
    void responseUsesProblemJsonMediaType() {
        Response response = Problem.of(ProblemType.BAD_REQUEST, "bad", "/a").toResponse();

        assertThat(response.getStatus()).isEqualTo(400);
        assertThat(response.getMediaType().toString()).isEqualTo("application/problem+json");
        assertThat(response.getEntity()).isInstanceOf(Problem.class);
    }
}
