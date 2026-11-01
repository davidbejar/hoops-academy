package com.hoopsacademy.game.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.game.application.GetMatchEvents;
import com.hoopsacademy.game.application.IngestEventBatch;
import com.hoopsacademy.game.application.SubmittedEvent;
import com.hoopsacademy.game.domain.MatchId;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.UUID;
import java.util.stream.StreamSupport;
import org.eclipse.microprofile.jwt.JsonWebToken;

/**
 * Offline sync of match events. The body is read as raw JSON so every event is validated on its own against the
 * JSON Schema: a bad event is REJECTED (SCHEMA_INVALID) without failing the batch. Per-event authorization happens in
 * the use case; whole-request errors are 400 (not a batch, empty, more than 500 events) and 404 (unknown match).
 */
@Path("/api/game/matches/{matchId}")
@Produces(MediaType.APPLICATION_JSON)
public class MatchEventResource {

    private final IngestEventBatch ingest;
    private final GetMatchEvents getEvents;
    private final MatchEventDecoder decoder;
    private final ObjectMapper json;
    private final SecurityIdentity identity;

    public MatchEventResource(IngestEventBatch ingest, GetMatchEvents getEvents, MatchEventDecoder decoder,
            ObjectMapper json, SecurityIdentity identity) {
        this.ingest = ingest;
        this.getEvents = getEvents;
        this.decoder = decoder;
        this.json = json;
        this.identity = identity;
    }

    @POST
    @Path("/events:batch")
    @Consumes(MediaType.APPLICATION_JSON)
    public MatchEventDtos.BatchResultDto submit(@PathParam("matchId") UUID matchId, JsonNode body) {
        JsonNode events = body == null ? null : body.get("events");
        if (events == null || !events.isArray() || events.isEmpty()) {
            throw new BadRequestException("The body must be {\"events\": [...]} with at least one event");
        }
        if (events.size() > IngestEventBatch.MAX_BATCH) {
            throw new BadRequestException("At most " + IngestEventBatch.MAX_BATCH + " events per batch");
        }
        List<SubmittedEvent> submitted = StreamSupport.stream(events.spliterator(), false).map(decoder::decode).toList();
        return MatchEventDtos.BatchResultDto.from(ingest.handle(MatchId.of(matchId), submitted, displayName()));
    }

    @GET
    @Path("/events")
    public MatchEventDtos.MatchEventFeedDto feed(
            @PathParam("matchId") UUID matchId,
            @QueryParam("after") @DefaultValue("0") @Min(0) long after,
            @QueryParam("limit") @DefaultValue("500") @Min(1) @Max(1000) int limit) {
        return MatchEventDtos.MatchEventFeedDto.from(json, getEvents.handle(MatchId.of(matchId), after, limit));
    }

    /** The caller's name for audit display: the token's {@code name} claim, else the principal name. */
    private String displayName() {
        if (identity.getPrincipal() instanceof JsonWebToken token && token.getClaim("name") instanceof String name
                && !name.isBlank()) {
            return name;
        }
        return identity.getPrincipal().getName();
    }
}
