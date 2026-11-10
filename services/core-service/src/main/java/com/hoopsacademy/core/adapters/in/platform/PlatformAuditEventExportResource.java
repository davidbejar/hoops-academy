package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.in.export.AuditCsv;
import com.hoopsacademy.core.adapters.in.export.ExportFileName;
import com.hoopsacademy.core.adapters.in.export.ExportLabels;
import com.hoopsacademy.core.adapters.in.export.ExportLanguage;
import com.hoopsacademy.core.adapters.in.shared.AuditDtos;
import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.CsvResponse;
import com.hoopsacademy.core.adapters.in.shared.Params;
import com.hoopsacademy.core.application.export.AuditSheet;
import com.hoopsacademy.core.application.export.ExportPlatformAuditTrail;
import jakarta.annotation.security.RolesAllowed;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Response;
import java.util.List;

/** The audit trail of every academy, or of one, as a CSV file for super admins (ADR-0048; no {@code X-Tenant-Id}). */
@Path("/platform/audit-events:export")
@RolesAllowed(CallerIdentity.SUPER_ADMIN)
public class PlatformAuditEventExportResource {

    private final ExportPlatformAuditTrail trail;

    public PlatformAuditEventExportResource(ExportPlatformAuditTrail trail) {
        this.trail = trail;
    }

    @GET
    @Produces("text/csv")
    public Response export(@QueryParam("tenantId") String tenantId, @QueryParam("from") String from,
            @QueryParam("to") String to, @QueryParam("action") List<String> actions,
            @HeaderParam(CsvResponse.ACCEPT_LANGUAGE) String acceptLanguage) {
        AuditSheet sheet = trail.export(Params.uuid("tenantId", tenantId).map(TenantId::new),
                AuditDtos.filter(from, to, actions));
        byte[] file = AuditCsv.platform(sheet, ExportLabels.of(ExportLanguage.negotiate(acceptLanguage)));
        return CsvResponse.of(file, ExportFileName.csv(sheet.origin().academySlug(), sheet.origin().day(), "audit"));
    }
}
