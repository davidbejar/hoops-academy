package com.hoopsacademy.core.adapters.out.client;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

/**
 * pdf-service's sheet API (ADR-0051 §3, {@code libs/contracts/openapi/pdf.yaml}), internal only. Built by
 * {@link PdfServiceRosterPrinter} with core's client-credentials token; an error status is a
 * {@link jakarta.ws.rs.WebApplicationException}.
 */
@Path("/internal/pdf")
@FunctionalInterface
public interface PdfServiceClient {

    @POST
    @Path("/team-roster")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces("application/pdf")
    byte[] teamRoster(TeamRosterRequestDto request);
}
