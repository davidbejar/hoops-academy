package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.export.AuditCsv;
import com.hoopsacademy.core.adapters.in.export.ExportFileName;
import com.hoopsacademy.core.adapters.in.export.ExportLabels;
import com.hoopsacademy.core.adapters.in.export.ExportLanguage;
import com.hoopsacademy.core.adapters.in.shared.AuditDtos;
import com.hoopsacademy.core.adapters.in.shared.CsvResponse;
import com.hoopsacademy.core.application.export.AuditSheet;
import com.hoopsacademy.core.application.export.ExportAuditTrail;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Response;
import java.util.List;

/** The academy's audit trail as a CSV file (ADMIN; the filters and masking of the list; ADR-0048). */
@Path("/api/core/audit-events:export")
public class AuditEventExportResource {

    private final ExportAuditTrail trail;

    public AuditEventExportResource(ExportAuditTrail trail) {
        this.trail = trail;
    }

    @GET
    @Produces("text/csv")
    public Response export(@QueryParam("from") String from, @QueryParam("to") String to,
            @QueryParam("action") List<String> actions,
            @HeaderParam(CsvResponse.ACCEPT_LANGUAGE) String acceptLanguage) {
        AuditSheet sheet = trail.export(AuditDtos.filter(from, to, actions));
        byte[] file = AuditCsv.academy(sheet, ExportLabels.of(ExportLanguage.negotiate(acceptLanguage)));
        return CsvResponse.of(file, ExportFileName.csv(sheet.origin().academySlug(), sheet.origin().day(), "audit"));
    }
}
