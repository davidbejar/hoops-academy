package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.WithPasswordDto;
import com.hoopsacademy.core.application.members.Guardians;
import com.hoopsacademy.core.application.members.Guardians.NewGuardian;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.UUID;

/** A new guardian linked to a player, with a login when an e-mail is given (WP58) — ADMIN only. */
@Path("/api/core/guardians")
@RequiresTenantRole(TenantRole.ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class GuardianResource {

    /** Contract {@code CreateGuardianRequest}. */
    public record CreateRequest(
            @NotBlank @Size(max = 80) String givenName,
            @NotBlank @Size(max = 80) String familyName,
            @Email @Size(max = 254) String email,
            @Size(max = 32) String phone,
            @Pattern(regexp = Constraints.LOCALE) String locale,
            @NotNull UUID playerId) {

        NewGuardian toCommand() {
            return new NewGuardian(new PersonalData(givenName, familyName, email, phone, null, null,
                    locale == null ? null : AppLocale.fromCode(locale)), new PlayerId(playerId));
        }
    }

    private final Guardians guardians;

    public GuardianResource(Guardians guardians) {
        this.guardians = guardians;
    }

    /** Contract {@code GuardianLinkWithPassword}; the temporary password is shown once, never cached. */
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid @NotNull CreateRequest request, UriInfo uri) {
        WithPasswordDto<GuardianLinkDto> link = WithPasswordDto.of(guardians.add(request.toCommand()),
                GuardianLinkDto::of);
        return WithPasswordDto.noStore(Response.created(uri.getBaseUriBuilder().path("api/core/guardian-links")
                .path(link.body().id().toString()).build())).entity(link).build();
    }
}
