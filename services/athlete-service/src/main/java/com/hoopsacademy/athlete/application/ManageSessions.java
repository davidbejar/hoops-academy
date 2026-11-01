package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.SessionStatus;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TrainingSession;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Training sessions: calendar listing, ad-hoc creation, edits and cancellation. */
@ApplicationScoped
public class ManageSessions {

    static final int MAX_RANGE_DAYS = 366;
    private static final int DEFAULT_HORIZON_WEEKS = 8;

    public record NewSession(TeamId teamId, Instant startsAt, int durationMinutes, String location, UUID planId,
            String notes) {}

    /** A partial edit: {@code Optional.empty()} = untouched, a present optional holding null = clear. */
    public record SessionChange(Optional<Instant> startsAt, Optional<Integer> durationMinutes,
            Optional<Optional<String>> location, Optional<Optional<UUID>> planId, Optional<Optional<String>> notes,
            Optional<SessionStatus> status) {}

    /** Calendar query; dates are inclusive calendar dates in the tenant's time zone. */
    public record Calendar(Optional<TeamId> team, Optional<LocalDate> from, Optional<LocalDate> to,
            Optional<SessionStatus> status, int page, int size) {}

    private final SessionRepository sessions;
    private final RosterPort roster;
    private final TrainingAccess access;
    private final TenantZones zones;
    private final TenantClock clock;
    private final PlanRepository plans;

    public ManageSessions(SessionRepository sessions, RosterPort roster, TrainingAccess access, TenantZones zones,
            TenantClock clock, PlanRepository plans) {
        this.plans = plans;
        this.sessions = sessions;
        this.roster = roster;
        this.access = access;
        this.zones = zones;
        this.clock = clock;
    }

    @Transactional
    public PageResult<TrainingSession> list(AuthzContext caller, Calendar calendar) {
        Set<TeamId> teams = null;
        if (calendar.team().isPresent()) {
            access.requireView(caller, calendar.team().get());
            teams = Set.of(calendar.team().get());
        } else if (!access.hasStaffRole(caller)) {
            teams = access.playerTeams(caller);
            if (teams.isEmpty()) {
                return new PageResult<>(java.util.List.of(), calendar.page(), calendar.size(), 0);
            }
        }
        ZoneId zone = clock.zoneOf(caller.tenantId());
        LocalDate today = clock.today(caller.tenantId());
        LocalDate from = calendar.from().orElseGet(() -> calendar.to().map(t -> t.minusDays(MAX_RANGE_DAYS - 1L)).orElse(today));
        LocalDate to = calendar.to().orElseGet(() -> calendar.from().isPresent()
                ? from.plusDays(MAX_RANGE_DAYS - 1L) : today.plusWeeks(DEFAULT_HORIZON_WEEKS));
        if (to.isBefore(from)) {
            throw new InvalidRequestException("to", "INVALID_RANGE", "to must not be before from");
        }
        if (java.time.temporal.ChronoUnit.DAYS.between(from, to) + 1 > MAX_RANGE_DAYS) {
            throw new InvalidRequestException("to", "RANGE_TOO_LARGE", "The date range is limited to 366 days");
        }
        return sessions.list(new SessionQuery(teams, from.atStartOfDay(zone).toInstant(),
                to.plusDays(1).atStartOfDay(zone).toInstant(), calendar.status(), calendar.page(), calendar.size()));
    }

    @Transactional
    public TrainingSession get(AuthzContext caller, SessionId id) {
        TrainingSession session = sessions.find(id).orElseThrow(() -> new NotFoundException("Session not found"));
        access.requireView(caller, session.teamId());
        return session;
    }

    @Transactional
    public TrainingSession createAdHoc(AuthzContext caller, NewSession request) {
        access.requireManage(caller, request.teamId());
        roster.teamRoster(caller.tenantId(), request.teamId());
        requirePlanExists(request.planId());
        zones.remember(caller);
        TrainingSession session = TrainingSession.adHoc(request.teamId(), request.startsAt(),
                request.durationMinutes(), request.location(), request.planId(), request.notes());
        sessions.save(session);
        return session;
    }

    @Transactional
    public TrainingSession update(AuthzContext caller, SessionId id, SessionChange change) {
        TrainingSession current = sessions.find(id).orElseThrow(() -> new NotFoundException("Session not found"));
        access.requireManage(caller, current.teamId());
        change.planId().flatMap(p -> p).ifPresent(this::requirePlanExists);
        TrainingSession edited = current.edited(
                change.startsAt().orElse(current.startsAt()),
                change.durationMinutes().orElse(current.durationMinutes()),
                Patches.apply(change.location(), current.location()),
                Patches.apply(change.planId(), current.planId()),
                Patches.apply(change.notes(), current.notes()),
                change.status().orElse(current.status()));
        sessions.save(edited);
        return edited;
    }

    /** A plan or template visible to the tenant; the edit marks the session {@code manually_edited}, so a re-plan keeps it. */
    private void requirePlanExists(UUID planId) {
        if (planId != null && !plans.exists(new PlanId(planId))) {
            throw new NotFoundException("Plan not found");
        }
    }

    @Transactional
    public TrainingSession cancel(AuthzContext caller, SessionId id, String reason) {
        TrainingSession current = sessions.find(id).orElseThrow(() -> new NotFoundException("Session not found"));
        access.requireManage(caller, current.teamId());
        TrainingSession cancelled = current.cancelled(reason);
        sessions.save(cancelled);
        return cancelled;
    }
}
