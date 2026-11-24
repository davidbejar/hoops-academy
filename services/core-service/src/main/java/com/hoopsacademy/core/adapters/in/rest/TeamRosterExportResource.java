package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.i18n.AcceptLanguage;
import com.hoopsacademy.core.adapters.in.export.AcceptedFormat;
import com.hoopsacademy.core.adapters.in.export.ExportFileName;
import com.hoopsacademy.core.adapters.in.export.ExportLabels;
import com.hoopsacademy.core.adapters.in.export.RosterCsv;
import com.hoopsacademy.core.adapters.in.shared.ExportResponse;
import com.hoopsacademy.core.application.export.ExportFormat;
import com.hoopsacademy.core.application.export.ExportOrigin;
import com.hoopsacademy.core.application.export.ExportTeamRoster;
import com.hoopsacademy.core.application.export.PrintTeamRoster;
import com.hoopsacademy.core.application.export.PrintTeamRoster.PrintedRoster;
import com.hoopsacademy.core.application.export.RosterSheet;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

/**
 * The team roster with guardians and staff (ADMIN and the team's current COACH; ADR-0048): a CSV file, or with
 * {@code Accept: application/pdf} the printed sheet (WP116, decision 89). Never logged.
 */
@Path("/api/core/teams/{teamId}/roster:export")
public class TeamRosterExportResource {

    private final ExportTeamRoster roster;
    private final PrintTeamRoster printer;

    public TeamRosterExportResource(ExportTeamRoster roster, PrintTeamRoster printer) {
        this.roster = roster;
        this.printer = printer;
    }

    @GET
    @Produces({"text/csv", "application/pdf"})
    public Response export(@PathParam("teamId") UUID team,
            @HeaderParam(ExportResponse.ACCEPT_LANGUAGE) String acceptLanguage, @Context HttpHeaders headers) {
        AppLocale language = AppLocale.of(AcceptLanguage.negotiate(acceptLanguage));
        return AcceptedFormat.of(headers.getAcceptableMediaTypes()) == ExportFormat.PDF
                ? pdf(new TeamId(team), language)
                : csv(new TeamId(team), language);
    }

    private Response csv(TeamId team, AppLocale language) {
        RosterSheet sheet = roster.export(team);
        byte[] file = RosterCsv.render(sheet, ExportLabels.of(language));
        return ExportResponse.csv(file,
                ExportFileName.csv(sheet.origin().academySlug(), sheet.origin().day(), "roster", sheet.teamName()));
    }

    private Response pdf(TeamId team, AppLocale language) {
        PrintedRoster printed = printer.print(team, language);
        ExportOrigin origin = printed.sheet().origin();
        return ExportResponse.of(printed.pdf(), AcceptedFormat.PDF.toString(),
                ExportFileName.pdf(origin.academySlug(), origin.day(), "roster", printed.sheet().teamName()));
    }
}
