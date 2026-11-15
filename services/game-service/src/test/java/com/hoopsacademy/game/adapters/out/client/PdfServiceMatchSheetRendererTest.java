package com.hoopsacademy.game.adapters.out.client;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.http.Fault;
import com.github.tomakehurst.wiremock.verification.LoggedRequest;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.application.sheet.MatchSheet;
import com.hoopsacademy.game.application.sheet.MatchSheetRenderer;
import com.hoopsacademy.game.application.sheet.PdfFile;
import com.hoopsacademy.game.application.sheet.SheetLanguage;
import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.projection.PeriodScore;
import com.hoopsacademy.game.domain.projection.StatLine;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import com.hoopsacademy.game.support.LogCapture;
import com.hoopsacademy.game.support.PdfServiceStubs;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * The match sheet through pdf-service (WP117; WP111 handover): game's client-credentials token, the body of pdf.yaml
 * {@code MatchSheetRequest}, the file and its name back; every failure is a 503 {@code UPSTREAM_UNAVAILABLE} whose
 * message, like every log line, names no player (docs/security/privacy-threat-model.md).
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class PdfServiceMatchSheetRendererTest {

    static final String PLAYER = "Ana Ruiz";
    static final StatLine ANA = new StatLine(12, 2, 4, 2, 5, 2, 3, 3, 1, 4, 2, 1, 0, 2, 0, 0, 1500);
    static final StatLine BEA = new StatLine(3, 1, 2, 1, 1, 0, 2, 0, 0, 1, 1, 0, 1, 1, 1, 0, 600);
    static final MatchSheet SHEET = new MatchSheet(SheetLanguage.ID,
            new MatchSheet.Academy("Garuda Hoops", ZoneId.of("Asia/Jakarta")),
            new MatchSheet.Header("U14 Elang", "Tigers", HomeAway.HOME, Instant.parse("2026-11-14T09:00:00Z"),
                    "GOR Bulungan", MatchStatus.FINISHED, 4, 10),
            15, 12,
            List.of(new PeriodScore(1, 4, 2), new PeriodScore(2, 3, 4), new PeriodScore(3, 4, 2),
                    new PeriodScore(4, 2, 4), new PeriodScore(5, 2, 0)),
            ANA.plus(BEA),
            List.of(new MatchSheet.Line(PLAYER, new JerseyNumber("07"), true, ANA),
                    new MatchSheet.Line("Bea Gómez", null, false, BEA)));

    @InjectCoreWireMock
    WireMockServer wm;

    @Inject
    MatchSheetRenderer renderer;

    private final ObjectMapper json = new ObjectMapper();

    @BeforeEach
    void freshStubs() {
        CoreStubs.reset(wm);
    }

    @Test
    void theSheetIsRenderedWithGamesTokenAndComesBackWithItsName() {
        PdfServiceStubs.rendersMatchSheets(wm);

        PdfFile file = renderer.render(SHEET);

        assertThat(file.content()).isEqualTo(PdfServiceStubs.PDF);
        assertThat(file.fileName()).isEqualTo(PdfServiceStubs.FILE_NAME);
        LoggedRequest sent = PdfServiceStubs.sentMatchSheets(wm).getFirst();
        assertThat(sent.getHeader("Authorization")).isEqualTo("Bearer " + CoreStubs.SERVICE_TOKEN);
        assertThat(sent.getHeader("Content-Type")).startsWith("application/json");
    }

    @Test
    void theBodyIsTheContractsMatchSheetRequest() throws Exception {
        PdfServiceStubs.rendersMatchSheets(wm);

        renderer.render(SHEET);

        LoggedRequest sent = PdfServiceStubs.sentMatchSheets(wm).getFirst();
        assertThat(PdfServiceStubs.againstTheContract(sent).getMessages()).isEmpty();
        JsonNode body = json.readTree(sent.getBodyAsString());
        assertThat(body.at("/locale").asText()).isEqualTo("id");
        assertThat(body.at("/academy/name").asText()).isEqualTo("Garuda Hoops");
        assertThat(body.at("/academy/timeZone").asText()).isEqualTo("Asia/Jakarta");
        assertThat(body.at("/match/teamName").asText()).isEqualTo("U14 Elang");
        assertThat(body.at("/match/opponentName").asText()).isEqualTo("Tigers");
        assertThat(body.at("/match/homeAway").asText()).isEqualTo("HOME");
        assertThat(Instant.parse(body.at("/match/scheduledAt").asText())).isEqualTo(Instant.parse("2026-11-14T09:00:00Z"));
        assertThat(body.at("/match/venue").asText()).isEqualTo("GOR Bulungan");
        assertThat(body.at("/match/status").asText()).isEqualTo("FINISHED");
        assertThat(body.at("/match/periodCount").asInt()).isEqualTo(4);
        assertThat(body.at("/match/periodMinutes").asInt()).isEqualTo(10);
        assertThat(body.at("/score/team").asInt()).isEqualTo(15);
        assertThat(body.at("/score/opponent").asInt()).isEqualTo(12);
        assertThat(body.at("/periodScores")).hasSize(5);
        assertThat(body.at("/periodScores/4/period").asInt()).isEqualTo(5);
        assertThat(body.at("/periodScores/1/opponent").asInt()).isEqualTo(4);
        assertThat(body.at("/teamTotals/points").asInt()).isEqualTo(15);
        assertThat(body.at("/teamTotals/secondsPlayed").asInt()).isEqualTo(2100);
        assertThat(body.at("/players/0/displayName").asText()).isEqualTo(PLAYER);
        assertThat(body.at("/players/0/jerseyNumber").asText()).isEqualTo("07");
        assertThat(body.at("/players/0/wasStarter").asBoolean()).isTrue();
        assertThat(body.at("/players/0/stats/fg3Made").asInt()).isEqualTo(2);
        assertThat(body.at("/players/0/stats/defensiveRebounds").asInt()).isEqualTo(4);
        assertThat(body.at("/players/1/jerseyNumber").isNull()).isTrue();
        assertThat(body.at("/players/1/wasStarter").asBoolean()).isFalse();
        assertThat(body.at("/players/1/stats/unsportsmanlikeFouls").asInt()).isZero();
        assertThat(body.at("/players/1/stats/technicalFouls").asInt()).isEqualTo(1);
    }

    @Test
    void aSheetWithoutVenueSendsNoVenue() throws Exception {
        PdfServiceStubs.rendersMatchSheets(wm);
        MatchSheet.Header header = SHEET.header();
        MatchSheet noVenue = new MatchSheet(SheetLanguage.ES, SHEET.academy(), new MatchSheet.Header(header.teamName(),
                header.opponentName(), HomeAway.AWAY, header.scheduledAt(), null, MatchStatus.SCHEDULED, 4, 10),
                0, 0, List.of(), StatLine.ZERO, List.of());

        renderer.render(noVenue);

        LoggedRequest sent = PdfServiceStubs.sentMatchSheets(wm).getFirst();
        assertThat(PdfServiceStubs.againstTheContract(sent).getMessages()).isEmpty();
        JsonNode body = json.readTree(sent.getBodyAsString());
        assertThat(body.at("/locale").asText()).isEqualTo("es");
        assertThat(body.at("/match/venue").isMissingNode() || body.at("/match/venue").isNull()).isTrue();
        assertThat(body.at("/players")).isEmpty();
    }

    @ParameterizedTest(name = "pdf-service {0} {1}")
    @CsvSource({
        "400, VALIDATION_FAILED", "401, INVALID_TOKEN", "403, FORBIDDEN", "413, PAYLOAD_TOO_LARGE",
        "415, UNSUPPORTED_MEDIA_TYPE", "422, TOO_MANY_ROWS", "500, INTERNAL_ERROR", "503, AUTH_UNAVAILABLE"
    })
    void everyRefusalIsAnOutageThatNamesNoPlayer(int status, String code) {
        PdfServiceStubs.answersMatchSheets(wm, PdfServiceStubs.problem(status, code));

        try (LogCapture logs = LogCapture.start()) {
            assertThatThrownBy(() -> renderer.render(SHEET)).isInstanceOf(UpstreamUnavailableException.class)
                    .hasMessageContaining(String.valueOf(status)).hasMessageNotContaining(PLAYER);

            assertThat(logs.containing(PLAYER)).isEmpty();
        }
    }

    @Test
    void anAnswerThatIsNotAPdfIsAnOutage() {
        PdfServiceStubs.answersMatchSheets(wm, aResponse().withStatus(200)
                .withHeader("Content-Type", "application/json").withBody("{\"ok\":true}"));

        assertThatThrownBy(() -> renderer.render(SHEET)).isInstanceOf(UpstreamUnavailableException.class);
    }

    @Test
    void anUnreachableServiceIsAnOutage() {
        PdfServiceStubs.answersMatchSheets(wm, aResponse().withFault(Fault.CONNECTION_RESET_BY_PEER));

        try (LogCapture logs = LogCapture.start()) {
            assertThatThrownBy(() -> renderer.render(SHEET)).isInstanceOf(UpstreamUnavailableException.class)
                    .hasMessageNotContaining(PLAYER);

            assertThat(logs.containing(PLAYER)).isEmpty();
        }
    }

    @Test
    void aServiceSlowerThanTheReadTimeoutIsAnOutage() {
        PdfServiceStubs.answersMatchSheets(wm, aResponse().withStatus(200).withHeader("Content-Type", "application/pdf")
                .withBody(PdfServiceStubs.PDF).withFixedDelay(3_000));

        assertThatThrownBy(() -> renderer.render(SHEET)).isInstanceOf(UpstreamUnavailableException.class);
    }

    @Test
    void withoutAUsableFileNameTheSheetGetsAPlainOne() {
        PdfServiceStubs.answersMatchSheets(wm, aResponse().withStatus(200).withHeader("Content-Type", "application/pdf")
                .withHeader("Content-Disposition", "attachment; filename=\"../../etc/passwd\"")
                .withBody(PdfServiceStubs.PDF));

        assertThat(renderer.render(SHEET).fileName()).isEqualTo("hoops-match-sheet.pdf");
    }
}
