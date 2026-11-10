package com.hoopsacademy.core.adapters.in.export;

import static com.hoopsacademy.core.adapters.in.export.CsvDocument.date;
import static com.hoopsacademy.core.adapters.in.export.CsvDocument.number;
import static com.hoopsacademy.core.adapters.in.export.CsvDocument.text;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.adapters.in.export.CsvDocument.Cell;
import com.hoopsacademy.core.application.export.RosterSheet;
import com.hoopsacademy.core.application.export.RosterSheet.PlayerLine;
import com.hoopsacademy.core.application.export.RosterSheet.StaffLine;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Stream;

/**
 * The team roster file (ADR-0048): one row per player (person data, natural age category, eligibility of the
 * assignment, jersey) followed by each guardian in a repeated column group, as many groups as the player with the
 * most guardians needs (at least one); then the staff as rows of the same columns.
 */
public final class RosterCsv {

    private static final List<String> PERSON_COLUMNS = List.of("roster.role", "roster.givenName", "roster.familyName",
            "roster.birthDate", "roster.gender", "roster.ageCategory", "roster.eligibility", "roster.playUpLevels",
            "roster.jerseyNumber", "roster.joinedOn", "roster.email", "roster.phone");
    private static final List<String> GUARDIAN_COLUMNS = List.of("roster.guardianGivenName",
            "roster.guardianFamilyName", "roster.guardianEmail", "roster.guardianPhone");

    private RosterCsv() {}

    public static byte[] render(RosterSheet sheet, ExportLabels labels) {
        int groups = Math.max(1, sheet.players().stream().mapToInt(line -> line.guardians().size()).max().orElse(0));
        CsvDocument document = new CsvDocument(header(groups, labels));
        sheet.players().forEach(line -> document.row(player(line, groups, labels)));
        sheet.staff().forEach(line -> document.row(staff(line, groups, labels)));
        return document.bytes();
    }

    private static List<String> header(int groups, ExportLabels labels) {
        List<String> header = new ArrayList<>(PERSON_COLUMNS.stream().map(labels::text).toList());
        for (int group = 1; group <= groups; group++) {
            int number = group;
            GUARDIAN_COLUMNS.forEach(key -> header.add(labels.text(key, number)));
        }
        return header;
    }

    private static List<Cell> player(PlayerLine line, int groups, ExportLabels labels) {
        PersonalData person = line.person().data();
        TeamPlayer assignment = line.assignment();
        List<Cell> cells = new ArrayList<>(List.of(text(labels.role(TenantRole.PLAYER)), text(person.givenName()),
                text(person.familyName()), date(person.birthDate()), text(labels.gender(person.gender())),
                text(line.naturalCategory() == null ? null : line.naturalCategory().name()),
                text(labels.text("eligibility." + standing(assignment))), number(assignment.playUpLevels()),
                text(assignment.jersey() == null ? null : assignment.jersey().value()), date(assignment.joinedOn()),
                text(person.email()), text(person.phone())));
        line.guardians().forEach(guardian -> cells.addAll(contact(guardian)));
        cells.addAll(Collections.nCopies((groups - line.guardians().size()) * GUARDIAN_COLUMNS.size(), text(null)));
        return cells;
    }

    private static List<Cell> staff(StaffLine line, int groups, ExportLabels labels) {
        PersonalData person = line.person().data();
        List<Cell> cells = new ArrayList<>(List.of(text(labels.role(line.member().role().tenantRole())),
                text(person.givenName()), text(person.familyName())));
        cells.addAll(Collections.nCopies(6, text(null)));
        cells.addAll(List.of(date(line.member().since()), text(person.email()), text(person.phone())));
        cells.addAll(Collections.nCopies(groups * GUARDIAN_COLUMNS.size(), text(null)));
        return cells;
    }

    private static List<Cell> contact(Person guardian) {
        PersonalData data = guardian.data();
        return Stream.of(data.givenName(), data.familyName(), data.email(), data.phone()).map(CsvDocument::text)
                .toList();
    }

    /** The stored state of the assignment, as the roster screen shows it. */
    private static String standing(TeamPlayer assignment) {
        if (!assignment.isValid()) {
            return "INELIGIBLE";
        }
        return assignment.playUpLevels() > 0 ? "PLAY_UP" : "ELIGIBLE";
    }
}
