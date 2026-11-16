package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.sheet.GetMatchSheetPdf;
import com.hoopsacademy.game.application.sheet.PdfFile;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

/**
 * The match sheet PDF (contract getMatchSheetPdf, WP117): who may read it and which lines it prints are the box
 * score's, decided by the use case; the file is never cached.
 */
@Path("/api/game/matches/{matchId}/box-score:pdf")
public class MatchSheetPdfResource {

    static final String APPLICATION_PDF = "application/pdf";

    private final GetMatchSheetPdf getMatchSheetPdf;

    public MatchSheetPdfResource(GetMatchSheetPdf getMatchSheetPdf) {
        this.getMatchSheetPdf = getMatchSheetPdf;
    }

    @GET
    @Produces(APPLICATION_PDF)
    public Response sheet(@PathParam("matchId") UUID matchId,
            @HeaderParam(HttpHeaders.ACCEPT_LANGUAGE) String acceptLanguage) {
        PdfFile file = getMatchSheetPdf.handle(MatchId.of(matchId), AcceptLanguage.negotiate(acceptLanguage));
        return Response.ok(file.content(), APPLICATION_PDF)
                .header("Content-Disposition", "attachment; filename=\"" + file.fileName() + "\"")
                .header(HttpHeaders.CACHE_CONTROL, "no-store").build();
    }
}
