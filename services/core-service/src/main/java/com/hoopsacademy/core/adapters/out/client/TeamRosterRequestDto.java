package com.hoopsacademy.core.adapters.out.client;

import com.hoopsacademy.core.application.export.RosterPrint;
import com.hoopsacademy.core.application.export.RosterSheet;
import com.hoopsacademy.core.application.export.RosterSheet.PlayerLine;
import com.hoopsacademy.core.application.export.RosterSheet.StaffLine;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Wire form of {@code pdf.yaml} {@code TeamRosterRequest} (WP116): what the roster export holds, in its order, plus
 * the sheet's heading. Absent optional values are omitted (core's {@code non_null} inclusion). Personal data:
 * never logged, never put on a span.
 */
public record TeamRosterRequestDto(String locale, AcademyDto academy, TeamDto team, List<PlayerDto> players,
        List<StaffDto> staff) {

    public record AcademyDto(String name, String timeZone) {}

    public record TeamDto(String name, String season, String category) {}

    public record PlayerDto(String givenName, String familyName, LocalDate birthDate, String gender,
            String ageCategory, String eligibility, int playUpLevels, String jerseyNumber, LocalDate joinedOn,
            String email, String phone, List<GuardianDto> guardians) {}

    public record GuardianDto(String givenName, String familyName, String email, String phone) {}

    public record StaffDto(String role, String givenName, String familyName, LocalDate since, String email,
            String phone) {}

    public static TeamRosterRequestDto of(RosterPrint print) {
        RosterSheet sheet = print.sheet();
        return new TeamRosterRequestDto(print.language().code(),
                new AcademyDto(print.academyName(), sheet.origin().zone().getId()),
                new TeamDto(sheet.teamName(), print.seasonName(), print.categoryName()),
                sheet.players().stream().map(TeamRosterRequestDto::player).toList(),
                sheet.staff().stream().map(TeamRosterRequestDto::staff).toList());
    }

    private static PlayerDto player(PlayerLine line) {
        PersonalData person = line.person().data();
        return new PlayerDto(person.givenName(), person.familyName(), person.birthDate(),
                Optional.ofNullable(person.gender()).map(Gender::name).orElse(null),
                Optional.ofNullable(line.naturalCategory()).map(AgeCategory::name).orElse(null), line.standing(),
                line.assignment().playUpLevels(),
                Optional.ofNullable(line.assignment().jersey()).map(JerseyNumber::value).orElse(null),
                line.assignment().joinedOn(), person.email(), person.phone(),
                line.guardians().stream().map(TeamRosterRequestDto::guardian).toList());
    }

    private static GuardianDto guardian(Person guardian) {
        PersonalData data = guardian.data();
        return new GuardianDto(data.givenName(), data.familyName(), data.email(), data.phone());
    }

    private static StaffDto staff(StaffLine line) {
        PersonalData person = line.person().data();
        return new StaffDto(line.member().role().name(), person.givenName(), person.familyName(),
                line.member().since(), person.email(), person.phone());
    }
}
