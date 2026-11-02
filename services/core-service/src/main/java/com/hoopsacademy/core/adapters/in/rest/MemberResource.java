package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.MergePatch;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.adapters.in.shared.WithPasswordDto;
import com.hoopsacademy.core.application.members.InviteMember;
import com.hoopsacademy.core.application.members.IssueTemporaryPassword;
import com.hoopsacademy.core.application.members.MemberCommands;
import com.hoopsacademy.core.application.members.MemberQueries;
import com.hoopsacademy.core.application.members.MemberView;
import com.hoopsacademy.core.application.port.PersonRepository.MemberFilter;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Members, their roles and deactivation — ADMIN only (authz matrix: "Members, roles, guardian links"). */
@Path("/api/core/members")
@RequiresTenantRole(TenantRole.ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class MemberResource {

    /** Contract {@code ReplaceMemberRolesRequest}. */
    public record ReplaceRolesRequest(
            @NotNull @NotEmpty List<@NotNull @Pattern(regexp = Constraints.TENANT_ROLE) String> roles) {}

    private final InviteMember inviteMember;
    private final IssueTemporaryPassword issueTemporaryPassword;
    private final MemberQueries queries;
    private final MemberCommands commands;

    public MemberResource(InviteMember inviteMember, IssueTemporaryPassword issueTemporaryPassword,
            MemberQueries queries, MemberCommands commands) {
        this.inviteMember = inviteMember;
        this.issueTemporaryPassword = issueTemporaryPassword;
        this.queries = queries;
        this.commands = commands;
    }

    @GET
    public MemberPageDto list(
            @QueryParam("role") @Pattern(regexp = Constraints.TENANT_ROLE) String role,
            @QueryParam("active") Boolean active,
            @QueryParam("q") @Size(max = 100) String query,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        MemberFilter filter = new MemberFilter(Optional.ofNullable(role).map(TenantRole::valueOf),
                Optional.ofNullable(active), Optional.ofNullable(query).filter(q -> !q.isBlank()));
        PageResult<MemberView> result = queries.list(filter, new PageRequest(page, size));
        return new MemberPageDto(result.items().stream().map(MemberDto::of).toList(), PageMetaDto.of(result));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response invite(@Valid @NotNull InviteMemberRequest request, UriInfo uri) {
        WithPasswordDto<MemberDto> member = WithPasswordDto.of(inviteMember.handle(request.toCommand()), MemberDto::of);
        return WithPasswordDto.noStore(Response.created(
                        uri.getAbsolutePathBuilder().path(member.body().personId().toString()).build()))
                .entity(member).build();
    }

    /** A new temporary password while the invitation is pending (ADR-0024); shown once, never cached. */
    @POST
    @Path("/{personId}/temporary-password")
    public Response issueTemporaryPassword(@PathParam("personId") UUID personId) {
        return WithPasswordDto.noStore(Response.ok())
                .entity(WithPasswordDto.of(issueTemporaryPassword.handle(new PersonId(personId)), MemberDto::of))
                .build();
    }

    @GET
    @Path("/{personId}")
    public MemberDto get(@PathParam("personId") UUID personId) {
        return MemberDto.of(queries.get(new PersonId(personId)));
    }

    @PATCH
    @Path("/{personId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public MemberDto update(@PathParam("personId") UUID personId, @NotNull JsonNode body) {
        MergePatch patch = MergePatch.of(body);
        PersonalDataChanges changes = new PersonalDataChanges(
                patch.requiredText("givenName", 80),
                patch.requiredText("familyName", 80),
                patch.email("email", true),
                patch.text("phone", 32),
                patch.parsed("birthDate", true, LocalDate::parse),
                patch.parsed("gender", true, Gender::valueOf),
                patch.parsed("locale", false, AppLocale::fromCode));
        patch.validate(true);
        return MemberDto.of(commands.updateData(new PersonId(personId), changes));
    }

    @PUT
    @Path("/{personId}/roles")
    @Consumes(MediaType.APPLICATION_JSON)
    public MemberDto replaceRoles(@PathParam("personId") UUID personId, @Valid @NotNull ReplaceRolesRequest request) {
        return MemberDto.of(commands.replaceRoles(new PersonId(personId), InviteMemberRequest.rolesOf(request.roles())));
    }

    @POST
    @Path("/{personId}/deactivate")
    public MemberDto deactivate(@PathParam("personId") UUID personId) {
        return MemberDto.of(commands.deactivate(new PersonId(personId)));
    }
}
