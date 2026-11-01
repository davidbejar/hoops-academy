package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlannedSlot;
import com.hoopsacademy.athlete.domain.ScheduleId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.SessionMaterialiser;
import com.hoopsacademy.athlete.domain.SessionStatus;
import com.hoopsacademy.athlete.domain.TrainingSchedule;
import com.hoopsacademy.athlete.domain.TrainingSession;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Creates the sessions of the recurring schedules for the next N weeks (8 by default) in the tenant's time zone.
 * Idempotent: a (schedule, start) pair is created at most once, so re-running creates nothing, and a cancelled
 * session keeps its row and is therefore never recreated. Runs inside the bound tenant (request or TenantScope).
 */
@ApplicationScoped
public class MaterialiseSessions {

    private final ScheduleRepository schedules;
    private final SessionRepository sessions;
    private final AttendanceRepository attendance;
    private final TenantClock clock;
    private final TenantContext tenantContext;
    private final int horizonWeeks;

    public MaterialiseSessions(ScheduleRepository schedules, SessionRepository sessions, AttendanceRepository attendance,
            TenantClock clock, TenantContext tenantContext,
            @ConfigProperty(name = "hoops.athlete.horizon-weeks", defaultValue = "8") int horizonWeeks) {
        this.schedules = schedules;
        this.sessions = sessions;
        this.attendance = attendance;
        this.clock = clock;
        this.tenantContext = tenantContext;
        this.horizonWeeks = horizonWeeks;
    }

    /** Adds the missing sessions of every active schedule of the bound tenant (the nightly job). @return how many were created */
    @Transactional
    public int forAllSchedules() {
        return materialise(schedules.findActive(Optional.empty(), Optional.empty()), false);
    }

    /**
     * After a schedule was created or changed: adds missing sessions and brings the untouched future ones in line
     * (moves/removes PLANNED sessions that nobody edited and that have no attendance). @return how many were created
     */
    @Transactional
    public int forChangedSchedule(TrainingSchedule schedule) {
        return materialise(List.of(schedule), true);
    }

    private int materialise(List<TrainingSchedule> active, boolean reconcile) {
        if (active.isEmpty()) {
            return 0;
        }
        TenantId tenant = tenantContext.requireTenantId();
        ZoneId zone = clock.zoneOf(tenant);
        Instant now = clock.now();
        LocalDate today = now.atZone(zone).toLocalDate();
        List<PlannedSlot> slots = SessionMaterialiser.slotsAhead(active, today, horizonWeeks, zone);

        Instant windowStart = today.atStartOfDay(zone).toInstant();
        Instant windowEnd = today.plusWeeks(horizonWeeks).atStartOfDay(zone).toInstant();
        Set<ScheduleId> ids = active.stream().map(TrainingSchedule::id).collect(Collectors.toSet());
        List<TrainingSession> existing = new ArrayList<>(sessions.findBySchedules(ids, windowStart, windowEnd));
        if (reconcile) {
            reconcileExisting(existing, slots, now);
        }
        Set<Key> taken = existing.stream().map(s -> new Key(s.scheduleId(), s.startsAt())).collect(Collectors.toSet());
        List<TrainingSession> created = slots.stream()
                .filter(slot -> !taken.contains(new Key(slot.scheduleId(), slot.startsAt())))
                .map(TrainingSession::materialised)
                .toList();
        sessions.saveAll(created);
        return created.size();
    }

    /** Untouched future sessions follow the new slots (location) or disappear when their slot is gone. */
    private void reconcileExisting(List<TrainingSession> existing, List<PlannedSlot> slots, Instant now) {
        Map<Key, PlannedSlot> wanted = new HashMap<>();
        slots.forEach(s -> wanted.put(new Key(s.scheduleId(), s.startsAt()), s));
        List<TrainingSession> untouched = existing.stream()
                .filter(s -> s.status() == SessionStatus.PLANNED && !s.manuallyEdited() && s.startsAt().isAfter(now))
                .toList();
        Set<SessionId> withAttendance = attendance.sessionsWithAttendance(untouched.stream().map(TrainingSession::id).toList());
        List<SessionId> toDelete = new ArrayList<>();
        List<TrainingSession> toUpdate = new ArrayList<>();
        for (TrainingSession session : untouched) {
            if (withAttendance.contains(session.id())) {
                continue;
            }
            PlannedSlot slot = wanted.get(new Key(session.scheduleId(), session.startsAt()));
            if (slot == null || !slot.endsAt().equals(session.endsAt())) {
                toDelete.add(session.id());
            } else if (!Objects.equals(slot.location(), session.location())) {
                toUpdate.add(new TrainingSession(session.id(), session.teamId(), session.scheduleId(),
                        session.startsAt(), session.endsAt(), slot.location(), session.planId(), session.status(),
                        session.notes(), session.cancelReason(), false));
            }
        }
        sessions.delete(toDelete);
        toUpdate.forEach(sessions::save);
        existing.removeIf(s -> toDelete.contains(s.id()));
    }

    private record Key(ScheduleId schedule, Instant startsAt) {}
}
