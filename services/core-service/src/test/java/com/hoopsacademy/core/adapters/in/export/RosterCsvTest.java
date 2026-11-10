package com.hoopsacademy.core.adapters.in.export;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.export.ExportOrigin;
import com.hoopsacademy.core.application.export.RosterSheet;
import com.hoopsacademy.core.application.export.RosterSheet.PlayerLine;
import com.hoopsacademy.core.application.export.RosterSheet.StaffLine;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
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
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** ADR-0048: the roster file — players with their guardians in repeated column groups, then the staff. */
class RosterCsvTest {

    private static final TeamId TEAM = TeamId.random();
    private static final LocalDate JOINED = LocalDate.of(2026, 9, 1);
    private static final AgeCategory U12 = new AgeCategory(AgeCategoryId.random(), "U12", "Under 12", 11, 2);
    private static final ExportOrigin ORIGIN = new ExportOrigin("hangtuah", ZoneId.of("Asia/Jakarta"),
            LocalDate.of(2026, 11, 10));

    @Test
    void playersWithTheirGuardiansThenTheStaffInEnglish() {
        PlayerLine uma = new PlayerLine(person("Uma", "Ant", "uma@example.com", "+34 600", LocalDate.of(2015, 6, 15),
                Gender.FEMALE), U12, assignment("7", 0, false), List.of(person("Gina", "Ant", "gina@example.com",
                "611", null, null), person("Gus", "Ant", null, null, null, null)));
        PlayerLine ben = new PlayerLine(person("Ben", "Bee", null, null, LocalDate.of(2014, 1, 2), Gender.MALE), null,
                assignment(null, 1, false), List.of());
        PlayerLine cal = new PlayerLine(person("Cal", "Cee", null, null, LocalDate.of(2013, 1, 2), Gender.MALE), U12,
                assignment("00", 0, true), List.of());
        StaffLine coach = new StaffLine(new TeamStaffMember(TEAM, PersonId.random(), StaffRole.COACH, JOINED),
                person("Cora", "Coach", "cora@example.com", "622", null, null));

        String csv = render(new RosterSheet(ORIGIN, "U12 Lions", List.of(uma, ben, cal), List.of(coach)), AppLocale.EN);

        assertThat(csv.split("\r\n")).containsExactly(
                "Role,Given name,Family name,Birth date,Gender,Age category,Eligibility,Play-up levels,Jersey number,"
                        + "Joined on,E-mail,Phone,Guardian 1 given name,Guardian 1 family name,Guardian 1 e-mail,"
                        + "Guardian 1 phone,Guardian 2 given name,Guardian 2 family name,Guardian 2 e-mail,"
                        + "Guardian 2 phone",
                "Player,Uma,Ant,2015-06-15,Female,Under 12,Eligible,0,7,2026-09-01,uma@example.com,'+34 600,Gina,Ant,"
                        + "gina@example.com,611,Gus,Ant,,",
                "Player,Ben,Bee,2014-01-02,Male,,Plays up,1,,2026-09-01,,,,,,,,,,",
                "Player,Cal,Cee,2013-01-02,Male,Under 12,Not eligible,0,00,2026-09-01,,,,,,,,,,",
                "Coach,Cora,Coach,,,,,,,2026-09-01,cora@example.com,622,,,,,,,,");
    }

    @Test
    void withoutGuardiansOneEmptyGroupKeepsTheColumnsStableAndLabelsFollowTheLanguage() {
        StaffLine assistant = new StaffLine(new TeamStaffMember(TEAM, PersonId.random(), StaffRole.ASSISTANT_COACH,
                JOINED), person("Ana", "Asis", null, null, null, null));

        String csv = render(new RosterSheet(ORIGIN, "Lions", List.of(), List.of(assistant)), AppLocale.ES);

        String[] lines = csv.split("\r\n");
        assertThat(lines[0]).startsWith("Rol,Nombre,Apellidos,").endsWith(",Tutor 1 teléfono");
        assertThat(lines[0].split(",")).hasSize(16);
        assertThat(lines).hasSize(2);
        assertThat(lines[1]).startsWith("Entrenador asistente,Ana,Asis,");
    }

    @Test
    void theFileStartsWithTheBom() {
        byte[] bytes = RosterCsv.render(new RosterSheet(ORIGIN, "Lions", List.of(), List.of()),
                ExportLabels.of(AppLocale.ID));

        assertThat(bytes[0]).isEqualTo((byte) 0xEF);
        assertThat(new String(bytes, StandardCharsets.UTF_8)).startsWith("﻿Peran,");
    }

    private static String render(RosterSheet sheet, AppLocale locale) {
        byte[] bytes = RosterCsv.render(sheet, ExportLabels.of(locale));
        return new String(bytes, 3, bytes.length - 3, StandardCharsets.UTF_8);
    }

    private static Person person(String given, String family, String email, String phone, LocalDate birth,
            Gender gender) {
        Set<TenantRole> roles = birth == null ? Set.of(TenantRole.PARENT) : Set.of(TenantRole.PLAYER);
        return Person.create(PersonId.random(), new PersonalData(given, family, email, phone, birth, gender,
                AppLocale.EN), roles, Instant.parse("2026-01-01T00:00:00Z"));
    }

    private static TeamPlayer assignment(String jersey, int playUp, boolean invalid) {
        TeamPlayer open = TeamPlayer.assign(TEAM, PlayerId.random(), JerseyNumber.ofNullable(jersey), JOINED, playUp);
        return invalid ? open.invalidate(EligibilityReason.CATEGORY_TOO_LOW, Instant.parse("2026-10-01T00:00:00Z"))
                : open;
    }
}
