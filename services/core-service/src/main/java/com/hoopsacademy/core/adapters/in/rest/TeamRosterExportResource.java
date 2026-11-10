package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.export.ExportFileName;
import com.hoopsacademy.core.adapters.in.export.ExportLabels;
import com.hoopsacademy.core.adapters.in.export.ExportLanguage;
import com.hoopsacademy.core.adapters.in.export.RosterCsv;
import com.hoopsacademy.core.adapters.in.shared.CsvResponse;
import com.hoopsacademy.core.application.export.ExportTeamRoster;
import com.hoopsacademy.core.application.export.RosterSheet;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

/** The team roster with guardians and staff as a CSV file (ADMIN and the team's COACH; ADR-0048). Never logged. */
@Path("/api/core/teams/{teamId}/roster:export")
public class TeamRosterExportResource {

    private final ExportTeamRoster roster;

    public TeamRosterExportResource(ExportTeamRoster roster) {
        this.roster = roster;
    }

    @GET
    @Produces("text/csv")
    public Response export(@PathParam("teamId") UUID team,
            @HeaderParam(CsvResponse.ACCEPT_LANGUAGE) String acceptLanguage) {
        RosterSheet sheet = roster.export(new TeamId(team));
        byte[] file = RosterCsv.render(sheet, ExportLabels.of(ExportLanguage.negotiate(acceptLanguage)));
        return CsvResponse.of(file, ExportFileName.csv(sheet.origin().academySlug(), sheet.origin().day(), "roster",
                sheet.teamName()));
    }
}
