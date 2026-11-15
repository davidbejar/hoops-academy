package com.hoopsacademy.game.adapters.out.client;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/**
 * pdf-service {@code /internal/pdf/**} (libs/contracts/openapi/pdf.yaml), built by {@link PdfServiceMatchSheetRenderer}
 * with game's client-credentials token. No class-level {@code @Path}: an {@code /internal} interface would also be
 * scanned as a server resource (see common's {@code CoreInternalClient}).
 */
interface PdfServiceClient {

    String APPLICATION_PDF = "application/pdf";

    @POST
    @Path("/internal/pdf/match-sheet")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces({APPLICATION_PDF, "application/problem+json"})
    Response renderMatchSheet(MatchSheetBody body);
}
