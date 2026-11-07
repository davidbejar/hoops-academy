package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.adapters.in.shared.WithPasswordDto;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.application.signup.DecideAcademyRequest;
import com.hoopsacademy.core.application.signup.SubmitAcademyRequest;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.signup.AcademyName;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import com.hoopsacademy.core.domain.signup.AcademyRequestId;
import com.hoopsacademy.core.domain.signup.AcademyRequestStatus;
import com.hoopsacademy.core.domain.signup.Requester;
import com.hoopsacademy.core.domain.signup.RequesterRole;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.jboss.logging.Logger;

/**
 * Invitation-only sign-up (WP90, ADR-0044): the landing page's public request and the super admin's workbench. The
 * class is {@code super_admin}; only {@link #submit} is open, deliberately (rate-limited at the gateway). A filled
 * honeypot ({@code website}, hidden on the page) is answered like any request and dropped here.
 */
@Path("/platform/academy-requests")
@RolesAllowed(CallerIdentity.SUPER_ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class PlatformAcademyRequestResource {

    private static final Logger LOG = Logger.getLogger(PlatformAcademyRequestResource.class);
    private static final Map<String, String> RECEIVED = Map.of("status", "RECEIVED");

    private final SubmitAcademyRequest submitRequest;
    private final DecideAcademyRequest decisions;
    private final CallerIdentity caller;

    public PlatformAcademyRequestResource(SubmitAcademyRequest submitRequest, DecideAcademyRequest decisions,
            CallerIdentity caller) {
        this.submitRequest = submitRequest;
        this.decisions = decisions;
        this.caller = caller;
    }

    /** The one anonymous operation of the platform (ADR-0044): the same 202 whatever happened to the request. */
    @POST
    @PermitAll
    @Consumes(MediaType.APPLICATION_JSON)
    public Response submit(@Valid @NotNull SubmitAcademyRequestBody body) {
        if (body.honeypotFilled()) {
            LOG.info("Academy request dropped: honeypot filled");
        } else {
            submitRequest.handle(Requester.of(body.name(), body.email(), RequesterRole.valueOf(body.role()),
                    body.locale() == null ? null : AppLocale.fromCode(body.locale())), AcademyName.of(body.academyName()));
        }
        return Response.accepted(RECEIVED).build();
    }

    @GET
    public AcademyRequestPageDto list(
            @QueryParam("status") @Pattern(regexp = "PENDING|ACCEPTED|REJECTED") String status,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PageResult<AcademyRequest> result = decisions.list(
                Optional.ofNullable(status).map(AcademyRequestStatus::valueOf), new PageRequest(page, size));
        return new AcademyRequestPageDto(result.items().stream().map(AcademyRequestDto::of).toList(),
                PageMetaDto.of(result));
    }

    @POST
    @Path("/{requestId: [0-9a-fA-F-]+}:accept")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response accept(@PathParam("requestId") UUID id, @Valid @NotNull AcceptAcademyRequestBody body) {
        AcceptAcademyRequestBody.Admin admin = body.firstAdmin();
        WithTemporaryPassword<DecideAcademyRequest.AcceptedAcademy> accepted = decisions.accept(
                new AcademyRequestId(id),
                new DecideAcademyRequest.Acceptance(TenantSlug.of(body.slug()), Constraints.zone(body.timezone()),
                        AppLocale.fromCode(body.defaultLocale()), admin.givenName(), admin.familyName(),
                        admin.locale() == null ? null : AppLocale.fromCode(admin.locale())),
                caller.current().subject());
        return WithPasswordDto.noStore(Response.ok())
                .entity(WithPasswordDto.of(accepted, AcademyRequestAcceptedDto::of)).build();
    }

    @POST
    @Path("/{requestId: [0-9a-fA-F-]+}:reject")
    @Consumes(MediaType.APPLICATION_JSON)
    public AcademyRequestDto reject(@PathParam("requestId") UUID id, @Valid @NotNull RejectAcademyRequestBody body) {
        return AcademyRequestDto.of(decisions.reject(new AcademyRequestId(id), body.reason(),
                caller.current().subject()));
    }
}
