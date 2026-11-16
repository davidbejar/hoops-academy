package com.hoopsacademy.core.adapters.out.client;

import static org.assertj.core.api.Assertions.assertThat;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.SimpleRequest;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.export.ExportOrigin;
import com.hoopsacademy.core.application.export.RosterPrint;
import com.hoopsacademy.core.application.export.RosterSheet;
import com.hoopsacademy.core.application.export.RosterSheet.PlayerLine;
import com.hoopsacademy.core.application.export.RosterSheet.StaffLine;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.export.ExportLimit;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import com.hoopsacademy.core.domain.shared.AppLocale;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.parser.OpenAPIV3Parser;
import io.swagger.v3.parser.core.models.ParseOptions;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

/**
 * WP116: the body core sends to pdf-service's {@code POST /internal/pdf/team-roster} is what the roster export holds,
 * in the shapes of {@code pdf.yaml} {@code TeamRosterRequest} (strict validator: an unknown property fails), and the
 * sheet limits of core equal the {@code maxItems} of that contract.
 */
class TeamRosterRequestDtoTest {

    private static final String PDF_SPEC = "/openapi/pdf.yaml";
    private static final TeamId TEAM = TeamId.random();
    private static final LocalDate JOINED = LocalDate.of(2026, 9, 1);
    private static final AgeCategory U12 = new AgeCategory(AgeCategoryId.random(), "U12", "Under 12", 11, 2);
    private static final ExportOrigin ORIGIN = new ExportOrigin("hangtuah", ZoneId.of("Asia/Jakarta"),
            LocalDate.of(2026, 11, 16));
    private static final ObjectMapper JSON = new ObjectMapper().findAndRegisterModules()
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
            .setDefaultPropertyInclusion(JsonInclude.Include.NON_NULL);

    @Test
    void theRosterIsSentInTheShapesOfThePdfContract() throws Exception {
        JsonNode body = JSON.valueToTree(TeamRosterRequestDto.of(print(AppLocale.ID)));

        assertThat(body.get("locale").asText()).isEqualTo("id");
        assertThat(body.get("academy").toString())
                .isEqualTo("{\"name\":\"Hang Tuah\",\"timeZone\":\"Asia/Jakarta\"}");
        assertThat(body.get("team").toString())
                .isEqualTo("{\"name\":\"U12 Lions\",\"season\":\"2026/27\",\"category\":\"Under 12\"}");
        JsonNode uma = body.get("players").get(0);
        assertThat(uma.toString()).isEqualTo("{\"givenName\":\"Uma\",\"familyName\":\"Ant\","
                + "\"birthDate\":\"2015-06-15\",\"gender\":\"FEMALE\",\"ageCategory\":\"Under 12\","
                + "\"eligibility\":\"ELIGIBLE\",\"playUpLevels\":0,\"jerseyNumber\":\"7\",\"joinedOn\":\"2026-09-01\","
                + "\"email\":\"uma@example.com\",\"phone\":\"+34 600\",\"guardians\":["
                + "{\"givenName\":\"Gina\",\"familyName\":\"Ant\",\"email\":\"gina@example.com\",\"phone\":\"611\"},"
                + "{\"givenName\":\"Gus\",\"familyName\":\"Ant\"}]}");
        assertThat(body.get("players").get(1).get("eligibility").asText()).isEqualTo("PLAY_UP");
        assertThat(body.get("players").get(1).get("playUpLevels").asInt()).isEqualTo(1);
        assertThat(body.get("players").get(1).has("ageCategory")).isFalse();
        assertThat(body.get("players").get(2).get("eligibility").asText()).isEqualTo("INELIGIBLE");
        assertThat(body.get("staff").toString()).isEqualTo("[{\"role\":\"COACH\",\"givenName\":\"Cora\","
                + "\"familyName\":\"Coach\",\"since\":\"2026-09-01\",\"email\":\"cora@example.com\"},"
                + "{\"role\":\"ASSISTANT_COACH\",\"givenName\":\"Ana\",\"familyName\":\"Assist\","
                + "\"since\":\"2026-09-01\"}]");
    }

    @Test
    void theStrictValidatorOfThePdfContractAcceptsTheBody() throws Exception {
        OpenApiInteractionValidator pdf = OpenApiInteractionValidator.createForSpecificationUrl(PDF_SPEC).build();
        for (AppLocale language : AppLocale.values()) {
            String body = JSON.writeValueAsString(TeamRosterRequestDto.of(print(language)));

            assertThat(pdf.validateRequest(SimpleRequest.Builder.post("/internal/pdf/team-roster")
                    .withContentType("application/json").withAuthorization("Bearer test").withBody(body).build())
                    .getMessages()).as(language.code()).isEmpty();
        }
    }

    @Test
    @SuppressWarnings("rawtypes")
    void theSheetLimitsAreThoseOfThePdfContract() {
        ParseOptions resolve = new ParseOptions();
        resolve.setResolve(true);
        resolve.setResolveFully(true);
        Map<String, Schema> schemas = new OpenAPIV3Parser()
                .read(getClass().getResource(PDF_SPEC).toString(), null, resolve).getComponents().getSchemas();

        assertThat(property(schemas, "TeamRosterRequest", "players").getMaxItems())
                .isEqualTo(ExportLimit.SHEET_MAX_PLAYERS);
        assertThat(property(schemas, "TeamRosterRequest", "staff").getMaxItems()).isEqualTo(ExportLimit.SHEET_MAX_STAFF);
        assertThat(property(schemas, "RosterPlayer", "guardians").getMaxItems())
                .isEqualTo(ExportLimit.SHEET_MAX_GUARDIANS);
    }

    @SuppressWarnings("rawtypes")
    private static Schema property(Map<String, Schema> schemas, String schema, String property) {
        return (Schema) schemas.get(schema).getProperties().get(property);
    }

    private static RosterPrint print(AppLocale language) {
        PlayerLine uma = new PlayerLine(person("Uma", "Ant", "uma@example.com", "+34 600", LocalDate.of(2015, 6, 15),
                Gender.FEMALE), U12, assignment("7", 0, false), List.of(person("Gina", "Ant", "gina@example.com",
                "611", null, null), person("Gus", "Ant", null, null, null, null)));
        PlayerLine ben = new PlayerLine(person("Ben", "Bee", null, null, null, null), null, assignment(null, 1, false),
                List.of());
        PlayerLine cal = new PlayerLine(person("Cal", "Cee", null, null, LocalDate.of(2013, 1, 2), Gender.MALE), U12,
                assignment("00", 0, true), List.of());
        StaffLine coach = new StaffLine(new TeamStaffMember(TEAM, PersonId.random(), StaffRole.COACH, JOINED),
                person("Cora", "Coach", "cora@example.com", null, null, null));
        StaffLine assistant = new StaffLine(new TeamStaffMember(TEAM, PersonId.random(), StaffRole.ASSISTANT_COACH,
                JOINED), person("Ana", "Assist", null, null, null, null));
        RosterSheet sheet = new RosterSheet(ORIGIN, "U12 Lions", List.of(uma, ben, cal), List.of(coach, assistant));
        return new RosterPrint(sheet, "Hang Tuah", "2026/27", "Under 12", language);
    }

    private static Person person(String given, String family, String email, String phone, LocalDate birth,
            Gender gender) {
        return Person.create(PersonId.random(), new PersonalData(given, family, email, phone, birth, gender,
                AppLocale.EN), Set.of(TenantRole.PARENT), Instant.parse("2026-01-01T00:00:00Z"));
    }

    private static TeamPlayer assignment(String jersey, int playUp, boolean invalid) {
        TeamPlayer open = TeamPlayer.assign(TEAM, PlayerId.random(), JerseyNumber.ofNullable(jersey), JOINED, playUp);
        return invalid ? open.invalidate(EligibilityReason.CATEGORY_TOO_LOW, Instant.parse("2026-10-01T00:00:00Z"))
                : open;
    }
}
