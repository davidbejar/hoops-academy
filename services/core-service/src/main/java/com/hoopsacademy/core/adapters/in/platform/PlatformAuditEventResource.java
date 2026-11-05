package com.hoopsacademy.core.adapters.in.platform;

import com.fasterxml.jackson.annotation.JsonUnwrapped;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.in.shared.AuditDtos;
import com.hoopsacademy.core.adapters.in.shared.AuditDtos.EventFields;
import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.adapters.in.shared.Params;
import com.hoopsacademy.core.application.audit.PlatformAuditEntry;
import com.hoopsacademy.core.application.audit.ReadPlatformAuditTrail;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.UUID;

/** The audit trail of every academy, for platform super admins (WP34, ADR-0029; no {@code X-Tenant-Id}). */
@Path("/platform/audit-events")
@RolesAllowed(CallerIdentity.SUPER_ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class PlatformAuditEventResource {

    /** Contract {@code PlatformAuditEvent}: the {@code AuditEvent} fields plus the academy. */
    public record PlatformAuditEventDto(@JsonUnwrapped EventFields event, UUID tenantId, String tenantName) {

        static PlatformAuditEventDto of(PlatformAuditEntry entry) {
            return new PlatformAuditEventDto(EventFields.of(entry.entry()), entry.entry().record().tenant().value(),
                    entry.tenantName());
        }
    }

    /** Contract {@code PlatformAuditEventPage}. */
    public record PlatformAuditEventPageDto(List<PlatformAuditEventDto> items, PageMetaDto page) {}

    private final ReadPlatformAuditTrail trail;

    public PlatformAuditEventResource(ReadPlatformAuditTrail trail) {
        this.trail = trail;
    }

    @GET
    public PlatformAuditEventPageDto list(@QueryParam("tenantId") String tenantId, @QueryParam("from") String from,
            @QueryParam("to") String to, @QueryParam("action") List<String> actions,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PageResult<PlatformAuditEntry> result = trail.list(Params.uuid("tenantId", tenantId).map(TenantId::new),
                AuditDtos.filter(from, to, actions), new PageRequest(page, size));
        return new PlatformAuditEventPageDto(result.items().stream().map(PlatformAuditEventDto::of).toList(),
                PageMetaDto.of(result));
    }
}
