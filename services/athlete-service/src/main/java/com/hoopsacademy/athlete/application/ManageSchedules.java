package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.ScheduleId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TrainingSchedule;
import com.hoopsacademy.athlete.domain.TrainingSession;
import com.hoopsacademy.athlete.domain.SessionStatus;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/** Training schedules: recurring weekly slots of a team (ADMIN / team staff write; any member of the audience reads). */
@ApplicationScoped
public class ManageSchedules {

    /** Field values of a new schedule. */
    public record NewSchedule(TeamId teamId, DayOfWeek dayOfWeek, LocalTime startTime, int durationMinutes,
            String location, LocalDate validFrom, LocalDate validUntil) {}

    /** A partial change: {@code Optional.empty()} = untouched, a present optional holding null = clear. */
    public record ScheduleChange(Optional<DayOfWeek> dayOfWeek, Optional<LocalTime> startTime,
            Optional<Integer> durationMinutes, Optional<Optional<String>> location, Optional<LocalDate> validFrom,
            Optional<Optional<LocalDate>> validUntil) {}

    private final ScheduleRepository schedules;
    private final SessionRepository sessions;
    private final AttendanceRepository attendance;
    private final RosterPort roster;
    private final TrainingAccess access;
    private final TenantZones zones;
    private final MaterialiseSessions materialise;
    private final TenantClock clock;

    public ManageSchedules(ScheduleRepository schedules, SessionRepository sessions, AttendanceRepository attendance,
            RosterPort roster, TrainingAccess access, TenantZones zones, MaterialiseSessions materialise,
            TenantClock clock) {
        this.schedules = schedules;
        this.sessions = sessions;
        this.attendance = attendance;
        this.roster = roster;
        this.access = access;
        this.zones = zones;
        this.materialise = materialise;
        this.clock = clock;
    }

    @Transactional
    public TrainingSchedule create(AuthzContext caller, NewSchedule request) {
        access.requireManage(caller, request.teamId());
        roster.teamRoster(caller.tenantId(), request.teamId());
        zones.remember(caller);
        TrainingSchedule schedule = TrainingSchedule.create(request.teamId(), request.dayOfWeek(),
                request.startTime(), request.durationMinutes(), request.location(), request.validFrom(),
                request.validUntil());
        schedules.save(schedule);
        materialise.forChangedSchedule(schedule);
        return schedule;
    }

    @Transactional
    public TrainingSchedule update(AuthzContext caller, ScheduleId id, ScheduleChange change) {
        TrainingSchedule current = schedules.find(id).orElseThrow(() -> new NotFoundException("Schedule not found"));
        access.requireManage(caller, current.teamId());
        TrainingSchedule changed = current.changedTo(
                change.dayOfWeek().orElse(current.dayOfWeek()),
                change.startTime().orElse(current.startTime()),
                change.durationMinutes().orElse(current.durationMinutes()),
                Patches.apply(change.location(), current.location()),
                change.validFrom().orElse(current.validFrom()),
                Patches.apply(change.validUntil(), current.validUntil()));
        zones.remember(caller);
        schedules.save(changed);
        materialise.forChangedSchedule(changed);
        return changed;
    }

    /** Ends the schedule and removes its future PLANNED sessions; past sessions and attendance stay. */
    @Transactional
    public void end(AuthzContext caller, ScheduleId id) {
        TrainingSchedule current = schedules.find(id).orElseThrow(() -> new NotFoundException("Schedule not found"));
        access.requireManage(caller, current.teamId());
        schedules.save(current.ended());
        List<TrainingSession> future = sessions.findFutureBySchedule(id, clock.now()).stream()
                .filter(s -> s.status() == SessionStatus.PLANNED)
                .toList();
        Set<SessionId> keep = attendance.sessionsWithAttendance(future.stream().map(TrainingSession::id).toList());
        sessions.delete(future.stream().map(TrainingSession::id).filter(sid -> !keep.contains(sid))
                .collect(Collectors.toList()));
    }

    @Transactional
    public TrainingSchedule get(AuthzContext caller, ScheduleId id) {
        TrainingSchedule schedule = schedules.find(id).orElseThrow(() -> new NotFoundException("Schedule not found"));
        access.requireView(caller, schedule.teamId());
        return schedule;
    }

    /** Staff roles see all schedules (optionally of one team); parents/players those of their players' teams. */
    @Transactional
    public List<TrainingSchedule> list(AuthzContext caller, Optional<TeamId> team, Optional<LocalDate> activeOn) {
        if (team.isPresent()) {
            access.requireView(caller, team.get());
        } else if (!access.hasStaffRole(caller)) {
            java.util.Set<TeamId> teams = access.playerTeams(caller);
            return teams.isEmpty() ? List.of()
                    : schedules.findActive(Optional.empty(), activeOn).stream().filter(s -> teams.contains(s.teamId())).toList();
        }
        return schedules.findActive(team, activeOn);
    }
}
