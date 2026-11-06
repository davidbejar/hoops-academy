package com.hoopsacademy.core.adapters.in.platform;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.PatchBody;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.adapters.in.shared.WithPasswordDto;
import com.hoopsacademy.core.application.members.MemberView;
import com.hoopsacademy.core.application.platform.ManageTenantAdmins;
import com.hoopsacademy.core.application.platform.ManageTenantAdmins.AddedAdmin;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.UUID;

/**
 * The administrators of a tenant, managed by platform super admins ({@code super_admin}, no {@code X-Tenant-Id}).
 * The one documented read of tenant content by the platform: the admins' identity only (ADR-0023).
 */
@Path("/platform/tenants/{tenantId}/admins")
@RolesAllowed(CallerIdentity.SUPER_ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class PlatformAdminResource {

    private final ManageTenantAdmins admins;

    public PlatformAdminResource(ManageTenantAdmins admins) {
        this.admins = admins;
    }

    @GET
    public TenantAdminPageDto list(@PathParam("tenantId") UUID tenantId,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PageResult<MemberView> result = admins.list(new TenantId(tenantId), new PageRequest(page, size));
        return new TenantAdminPageDto(result.items().stream().map(TenantAdminDto::of).toList(),
                PageMetaDto.of(result));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response add(@PathParam("tenantId") UUID tenantId, @Valid @NotNull AddTenantAdminRequest request,
            UriInfo uri) {
        AddedAdmin added = admins.add(new TenantId(tenantId), request.toPersonalData());
        WithPasswordDto<TenantAdminDto> admin = WithPasswordDto.of(
                new WithTemporaryPassword<>(added.admin(), added.temporaryPassword()), TenantAdminDto::of);
        Response.ResponseBuilder response = added.invited()
                ? Response.created(uri.getAbsolutePathBuilder().path(admin.body().personId().toString()).build())
                : Response.ok();
        return WithPasswordDto.noStore(response).entity(admin).build();
    }

    @PATCH
    @Path("/{personId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public TenantAdminDto update(@PathParam("tenantId") UUID tenantId, @PathParam("personId") UUID personId,
            @NotNull JsonNode body) {
        PatchBody patch = PatchBody.of(body);
        PersonalDataChanges changes = PersonalDataChanges.none()
                .withGivenName(patch.nonBlankText("givenName", 80))
                .withFamilyName(patch.nonBlankText("familyName", 80))
                .withEmail(patch.email("email"));
        patch.allowOnly("givenName", "familyName", "email");
        patch.validate();
        return TenantAdminDto.of(admins.update(new TenantId(tenantId), new PersonId(personId), changes));
    }

    @DELETE
    @Path("/{personId}")
    public Response remove(@PathParam("tenantId") UUID tenantId, @PathParam("personId") UUID personId) {
        admins.remove(new TenantId(tenantId), new PersonId(personId));
        return Response.noContent().build();
    }

    /** A new temporary password while the invitation is pending (ADR-0024); shown once, never cached. */
    @POST
    @Path("/{personId}/temporary-password")
    public Response issueTemporaryPassword(@PathParam("tenantId") UUID tenantId,
            @PathParam("personId") UUID personId) {
        WithPasswordDto<TenantAdminDto> issued = WithPasswordDto.of(
                admins.issueTemporaryPassword(new TenantId(tenantId), new PersonId(personId)), TenantAdminDto::of);
        return WithPasswordDto.noStore(Response.ok()).entity(issued).build();
    }
}
