package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.application.members.GuardianLinkService;
import com.hoopsacademy.core.application.members.GuardianLinkService.LinkView;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Guardian ↔ player links — ADMIN only. */
@Path("/api/core/guardian-links")
@RequiresTenantRole(TenantRole.ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class GuardianLinkResource {

    /** Contract {@code CreateGuardianLinkRequest}. */
    public record CreateRequest(@NotNull UUID guardianPersonId, @NotNull UUID playerId) {}

    /** Contract {@code GuardianLinkPage}. */
    public record PageDto(List<GuardianLinkDto> items, PageMetaDto page) {}

    private final GuardianLinkService links;

    public GuardianLinkResource(GuardianLinkService links) {
        this.links = links;
    }

    @GET
    public PageDto list(@QueryParam("playerId") UUID playerId, @QueryParam("guardianPersonId") UUID guardianPersonId,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PageResult<LinkView> result = links.list(Optional.ofNullable(playerId).map(PlayerId::new),
                Optional.ofNullable(guardianPersonId).map(PersonId::new), new PageRequest(page, size));
        return new PageDto(result.items().stream().map(GuardianLinkDto::of).toList(), PageMetaDto.of(result));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid @NotNull CreateRequest request, UriInfo uri) {
        GuardianLinkDto link = GuardianLinkDto.of(
                links.create(new PersonId(request.guardianPersonId()), new PlayerId(request.playerId())));
        return Response.created(uri.getAbsolutePathBuilder().path(link.id().toString()).build()).entity(link).build();
    }

    @DELETE
    @Path("/{guardianLinkId}")
    public void delete(@PathParam("guardianLinkId") UUID id) {
        links.delete(new GuardianLinkId(id));
    }
}
