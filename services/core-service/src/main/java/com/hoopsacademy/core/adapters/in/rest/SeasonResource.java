package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.core.adapters.in.shared.MergePatch;
import com.hoopsacademy.core.application.roster.RolloverSeason;
import com.hoopsacademy.core.application.roster.SeasonService;
import com.hoopsacademy.core.application.roster.SeasonService.NewSeason;
import com.hoopsacademy.core.application.roster.SeasonService.SeasonView;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonChanges;
import com.hoopsacademy.core.domain.roster.SeasonId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Seasons (any member reads; ADMIN writes) and the rollover into a new season. */
@Path("/api/core/seasons")
@Produces(MediaType.APPLICATION_JSON)
public class SeasonResource {

    /** Contract {@code SeasonInput}. */
    public record SeasonInput(@NotNull @Size(min = 1, max = 60) String name, @NotNull LocalDate startsOn,
            @NotNull LocalDate endsOn, @NotNull @Min(2000) @Max(2100) Integer referenceYear) {}

    /** Contract {@code Season}. */
    public record SeasonDto(UUID id, String name, LocalDate startsOn, LocalDate endsOn, int referenceYear,
            boolean current) {

        static SeasonDto of(SeasonView view) {
            Season season = view.season();
            return new SeasonDto(season.id().value(), season.name(), season.startsOn(), season.endsOn(),
                    season.referenceYear(), view.current());
        }
    }

    private final SeasonService seasons;
    private final RolloverSeason rollover;

    public SeasonResource(SeasonService seasons, RolloverSeason rollover) {
        this.seasons = seasons;
        this.rollover = rollover;
    }

    @GET
    public List<SeasonDto> list() {
        return seasons.list().stream().map(SeasonDto::of).toList();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid @NotNull SeasonInput input, UriInfo uri) {
        SeasonDto created = SeasonDto.of(seasons.create(new NewSeason(input.name(), input.startsOn(), input.endsOn(),
                input.referenceYear())));
        return Response.created(uri.getAbsolutePathBuilder().path(created.id().toString()).build()).entity(created).build();
    }

    @GET
    @Path("/{seasonId}")
    public SeasonDto get(@PathParam("seasonId") UUID id) {
        return SeasonDto.of(seasons.get(new SeasonId(id)));
    }

    @PATCH
    @Path("/{seasonId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public SeasonDto update(@PathParam("seasonId") UUID id, @NotNull JsonNode body) {
        MergePatch patch = MergePatch.of(body);
        SeasonChanges changes = new SeasonChanges(
                patch.requiredText("name", Season.MAX_NAME),
                patch.parsed("startsOn", false, LocalDate::parse),
                patch.parsed("endsOn", false, LocalDate::parse),
                patch.integer("referenceYear", false, Season.MIN_REFERENCE_YEAR, Season.MAX_REFERENCE_YEAR));
        patch.validate(true);
        return SeasonDto.of(seasons.update(new SeasonId(id), changes));
    }

    @POST
    @Path("/{seasonId}/rollover")
    @Consumes(MediaType.APPLICATION_JSON)
    public RolloverResultDto rollover(@PathParam("seasonId") UUID target, @Valid @NotNull RolloverRequest request) {
        return RolloverResultDto.of(rollover.rollover(new SeasonId(target), request.toCommand()));
    }
}
