package com.hoopsacademy.athlete.domain;

import java.time.LocalDate;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Builds the attendance sheet of a session: the team roster overlaid with recorded attendance and planned absences. */
public final class AttendanceSheet {

    private AttendanceSheet() {}

    /**
     * @param rosterPlayers  players of the team's current roster
     * @param recorded       attendance rows of the session (also for players that left the roster meanwhile)
     * @param absences       planned absences of those players, any dates
     * @param sessionDate    the session's calendar date in the tenant time zone
     */
    public static List<AttendanceEntry> build(Collection<PlayerId> rosterPlayers, Collection<Attendance> recorded,
            Collection<PlannedAbsence> absences, LocalDate sessionDate) {
        Map<PlayerId, Attendance> attendanceByPlayer =
                recorded.stream().collect(Collectors.toMap(Attendance::playerId, Function.identity()));
        Map<PlayerId, PlannedAbsence> absenceByPlayer = absences.stream()
                .filter(a -> a.covers(sessionDate))
                .collect(Collectors.toMap(PlannedAbsence::playerId, Function.identity(), AttendanceSheet::earliestCreated));
        return java.util.stream.Stream.concat(rosterPlayers.stream(), attendanceByPlayer.keySet().stream())
                .distinct()
                .sorted(Comparator.comparing(PlayerId::toString))
                .map(p -> new AttendanceEntry(p, Optional.ofNullable(attendanceByPlayer.get(p)),
                        Optional.ofNullable(absenceByPlayer.get(p))))
                .toList();
    }

    private static PlannedAbsence earliestCreated(PlannedAbsence a, PlannedAbsence b) {
        return a.createdAt().isAfter(b.createdAt()) ? b : a;
    }
}
