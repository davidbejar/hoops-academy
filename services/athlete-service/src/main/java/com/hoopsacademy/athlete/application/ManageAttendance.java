package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.Attendance;
import com.hoopsacademy.athlete.domain.AttendanceEntry;
import com.hoopsacademy.athlete.domain.AttendanceSheet;
import com.hoopsacademy.athlete.domain.AttendanceStatus;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.TrainingRuleViolation;
import com.hoopsacademy.athlete.domain.TrainingSession;
import com.hoopsacademy.athlete.domain.TrainingStateConflict;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;

/** Attendance of a session: the sheet (roster + planned-absence overlay) and recording by staff. */
@ApplicationScoped
public class ManageAttendance {

    /** One line of a recording request. */
    public record Mark(PlayerId playerId, AttendanceStatus status, Integer minutesLate, String note) {}

    private final SessionRepository sessions;
    private final AttendanceRepository attendance;
    private final AbsenceRepository absences;
    private final RosterPort roster;
    private final TrainingAccess access;
    private final TenantClock clock;

    public ManageAttendance(SessionRepository sessions, AttendanceRepository attendance, AbsenceRepository absences,
            RosterPort roster, TrainingAccess access, TenantClock clock) {
        this.sessions = sessions;
        this.attendance = attendance;
        this.absences = absences;
        this.roster = roster;
        this.access = access;
        this.clock = clock;
    }

    /**
     * ADMIN / staff of the team (also its former staff once the season has ended) see the whole sheet; a parent or
     * player sees only the entries of their own players and gets 404 when none of them is on the team. Other staff
     * roles get 403.
     */
    @Transactional
    public List<AttendanceEntry> sheet(AuthzContext caller, SessionId id) {
        TrainingSession session = sessions.find(id).orElseThrow(() -> new NotFoundException("Session not found"));
        List<AttendanceEntry> all = buildSheet(caller, session);
        if (access.seesAsStaff(caller, session.teamId())) {
            return all;
        }
        Set<PlayerId> related = access.relatedPlayers(caller);
        List<AttendanceEntry> own = all.stream().filter(e -> related.contains(e.playerId())).toList();
        if (own.isEmpty()) {
            if (access.hasStaffRole(caller)) {
                throw new AccessDeniedException("Only an administrator or staff of this team may see the sheet");
            }
            throw new NotFoundException("Session not found");
        }
        return own;
    }

    /** Upserts attendance for the listed players (others untouched) and returns the full sheet. */
    @Transactional
    public List<AttendanceEntry> record(AuthzContext caller, Actor actor, SessionId id, List<Mark> marks) {
        TrainingSession session = sessions.find(id).orElseThrow(() -> new NotFoundException("Session not found"));
        access.requireManage(caller, session.teamId());
        if (session.isCancelled()) {
            throw new TrainingStateConflict("Attendance cannot be recorded for a cancelled session", "SESSION_CANCELLED");
        }
        TeamRoster teamRoster = roster.teamRoster(caller.tenantId(), session.teamId());
        for (Mark mark : marks) {
            if (!teamRoster.hasPlayer(mark.playerId())) {
                throw new TrainingRuleViolation("Player " + mark.playerId() + " is not on the team", "PLAYER_NOT_IN_TEAM");
            }
        }
        var now = clock.now();
        attendance.upsertAll(marks.stream()
                .map(m -> new Attendance(id, m.playerId(), m.status(), m.minutesLate(), m.note(), actor, now))
                .toList());
        return buildSheet(caller, session);
    }

    private List<AttendanceEntry> buildSheet(AuthzContext caller, TrainingSession session) {
        TeamRoster teamRoster = roster.teamRoster(caller.tenantId(), session.teamId());
        LocalDate date = session.startsAt().atZone(clock.zoneOf(caller.tenantId())).toLocalDate();
        List<Attendance> recorded = attendance.findBySession(session.id());
        List<PlayerId> players = teamRoster.playerIds();
        return AttendanceSheet.build(players, recorded, absences.covering(players, date), date);
    }
}
