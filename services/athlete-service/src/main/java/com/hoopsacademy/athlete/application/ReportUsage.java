package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/** Usage counters of one tenant for platform statistics (read inside the tenant's RLS scope). */
@ApplicationScoped
public class ReportUsage {

    public record Usage(TenantId tenantId, Instant collectedAt, Map<String, Long> counters) {}

    private final TenantScope tenantScope;
    private final SessionRepository sessions;
    private final AttendanceRepository attendance;
    private final ScheduleRepository schedules;
    private final AbsenceRepository absences;
    private final PlanRepository plans;
    private final AssignmentRepository assignments;
    private final InjuryRepository injuries;
    private final MeasurementRepository measurements;
    private final TestResultRepository testResults;
    private final TenantClock clock;

    public ReportUsage(TenantScope tenantScope, SessionRepository sessions, AttendanceRepository attendance,
            ScheduleRepository schedules, AbsenceRepository absences, PlanRepository plans,
            AssignmentRepository assignments, InjuryRepository injuries, MeasurementRepository measurements,
            TestResultRepository testResults, TenantClock clock) {
        this.tenantScope = tenantScope;
        this.sessions = sessions;
        this.attendance = attendance;
        this.schedules = schedules;
        this.absences = absences;
        this.plans = plans;
        this.assignments = assignments;
        this.injuries = injuries;
        this.measurements = measurements;
        this.testResults = testResults;
        this.clock = clock;
    }

    public Usage forTenant(TenantId tenant) {
        Map<String, Long> counters = tenantScope.runAs(tenant, () -> {
            Map<String, Long> counts = new LinkedHashMap<>();
            counts.put("trainingSessions", sessions.count());
            counts.put("attendanceRecords", attendance.count());
            counts.put("trainingSchedules", schedules.count());
            counts.put("plannedAbsences", absences.count());
            counts.put("trainingPlans", plans.countTenantPlans());
            counts.put("planAssignments", assignments.countAssignments());
            counts.put("injuries", injuries.count());
            counts.put("bodyMeasurements", measurements.count());
            counts.put("physicalTestResults", testResults.count());
            return counts;
        });
        return new Usage(tenant, clock.now(), counters);
    }
}
