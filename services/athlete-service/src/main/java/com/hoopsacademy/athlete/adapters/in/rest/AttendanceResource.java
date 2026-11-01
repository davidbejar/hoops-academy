package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.ManageAttendance;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.UUID;

@Path("/api/athlete/training-sessions/{sessionId}/attendance")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class AttendanceResource {

    private final ManageAttendance attendance;
    private final TenantContext tenant;
    private final CallerActor actors;

    AttendanceResource(ManageAttendance attendance, TenantContext tenant, CallerActor actors) {
        this.attendance = attendance;
        this.tenant = tenant;
        this.actors = actors;
    }

    @GET
    public AttendanceDtos.Sheet sheet(@PathParam("sessionId") UUID sessionId) {
        return toSheet(sessionId, attendance.sheet(caller(), new SessionId(sessionId)));
    }

    @PUT
    public AttendanceDtos.Sheet record(@PathParam("sessionId") UUID sessionId,
            @Valid @NotNull AttendanceDtos.RecordRequest request) {
        List<ManageAttendance.Mark> marks = request.entries().stream()
                .map(e -> new ManageAttendance.Mark(new PlayerId(e.playerId()), e.status(), e.minutesLate(), e.note()))
                .toList();
        AuthzContext caller = caller();
        return toSheet(sessionId, attendance.record(caller, actors.of(caller), new SessionId(sessionId), marks));
    }

    private static AttendanceDtos.Sheet toSheet(UUID sessionId, List<com.hoopsacademy.athlete.domain.AttendanceEntry> entries) {
        return new AttendanceDtos.Sheet(sessionId, entries.stream().map(AttendanceDtos.Entry::from).toList());
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
