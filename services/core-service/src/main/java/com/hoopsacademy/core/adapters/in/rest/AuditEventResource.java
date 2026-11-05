package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.adapters.in.shared.AuditDtos;
import com.hoopsacademy.core.adapters.in.shared.AuditDtos.EventFields;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.application.audit.AuditEntry;
import com.hoopsacademy.core.application.audit.ReadAuditTrail;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

/** The academy's audit trail — ADMIN only (WP34, ADR-0029). */
@Path("/api/core/audit-events")
@RequiresTenantRole(TenantRole.ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class AuditEventResource {

    /** Contract {@code AuditEventPage}. */
    public record AuditEventPageDto(List<EventFields> items, PageMetaDto page) {}

    private final ReadAuditTrail trail;

    public AuditEventResource(ReadAuditTrail trail) {
        this.trail = trail;
    }

    @GET
    public AuditEventPageDto list(@QueryParam("from") String from, @QueryParam("to") String to,
            @QueryParam("action") List<String> actions,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PageResult<AuditEntry> result = trail.list(AuditDtos.filter(from, to, actions), new PageRequest(page, size));
        return new AuditEventPageDto(result.items().stream().map(EventFields::of).toList(), PageMetaDto.of(result));
    }
}
