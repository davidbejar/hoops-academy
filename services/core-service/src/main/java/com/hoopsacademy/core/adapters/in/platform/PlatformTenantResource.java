package com.hoopsacademy.core.adapters.in.platform;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.InvalidRequestException;
import com.hoopsacademy.core.adapters.in.shared.PatchBody;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.adapters.in.shared.Params;
import com.hoopsacademy.core.adapters.in.shared.WithPasswordDto;
import com.hoopsacademy.core.application.platform.CreateTenant;
import com.hoopsacademy.core.application.platform.CreateTenantCommand;
import com.hoopsacademy.core.application.platform.PlatformTenantQueries;
import com.hoopsacademy.core.application.platform.TenantLifecycle;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.application.usage.AggregateTenantUsage;
import com.hoopsacademy.core.application.usage.UsageHistory;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
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
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

/** Tenant lifecycle and statistics for platform super admins ({@code super_admin}); never tenant content. */
@Path("/platform/tenants")
@RolesAllowed(CallerIdentity.SUPER_ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class PlatformTenantResource {

    private static final int DEFAULT_HISTORY_DAYS = 90;
    private static final int MAX_HISTORY_DAYS = 366;

    private final CreateTenant createTenant;
    private final PlatformTenantQueries queries;
    private final TenantLifecycle lifecycle;
    private final AggregateTenantUsage usage;
    private final UsageHistory usageHistory;
    private final Clock clock;

    public PlatformTenantResource(CreateTenant createTenant, PlatformTenantQueries queries, TenantLifecycle lifecycle,
            AggregateTenantUsage usage, UsageHistory usageHistory, Clock clock) {
        this.createTenant = createTenant;
        this.queries = queries;
        this.lifecycle = lifecycle;
        this.usage = usage;
        this.usageHistory = usageHistory;
        this.clock = clock;
    }

    @GET
    public TenantPageDto list(
            @QueryParam("status") @Pattern(regexp = Constraints.TENANT_STATUS) String status,
            @QueryParam("q") @Size(max = 100) String query,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PageResult<Tenant> result = queries.list(Optional.ofNullable(status).map(TenantStatus::valueOf),
                Optional.ofNullable(query).filter(q -> !q.isBlank()), new PageRequest(page, size));
        return new TenantPageDto(result.items().stream().map(TenantDto::of).toList(), PageMetaDto.of(result));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid @NotNull CreateTenantRequest request, UriInfo uri) {
        CreateTenantRequest.FirstAdmin admin = request.firstAdmin();
        WithTemporaryPassword<Tenant> created = createTenant.handle(new CreateTenantCommand(
                TenantSlug.of(request.slug()), request.name(),
                Constraints.zone(request.timezone()), AppLocale.fromCode(request.defaultLocale()),
                new CreateTenantCommand.FirstAdmin(admin.email(), admin.givenName(), admin.familyName(),
                        admin.locale() == null ? null : AppLocale.fromCode(admin.locale()))));
        return WithPasswordDto.noStore(Response.created(uri.getAbsolutePathBuilder()
                        .path(created.value().id().toString()).build()))
                .entity(WithPasswordDto.of(created, TenantDto::of)).build();
    }

    @GET
    @Path("/{tenantId}")
    public TenantDto get(@PathParam("tenantId") UUID id) {
        return TenantDto.of(queries.get(new TenantId(id)));
    }

    @PATCH
    @Consumes(MediaType.APPLICATION_JSON)
    @Path("/{tenantId}")
    public TenantDto update(@PathParam("tenantId") UUID id, @NotNull JsonNode body) {
        PatchBody patch = PatchBody.of(body);
        Patch<String> name = patch.nonBlankText("name", 120);
        Patch<ZoneId> timezone = patch.parsed("timezone", Constraints::zone);
        Patch<AppLocale> locale = patch.parsed("defaultLocale", AppLocale::fromCode);
        patch.validate();
        return TenantDto.of(lifecycle.changeMasterData(new TenantId(id), name, timezone, locale));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Path("/{tenantId}/suspend")
    public TenantDto suspend(@PathParam("tenantId") UUID id, @Valid @NotNull TenantLifecycleRequest request) {
        return TenantDto.of(lifecycle.suspend(new TenantId(id), request.reason()));
    }

    @POST
    @Path("/{tenantId}/reactivate")
    public TenantDto reactivate(@PathParam("tenantId") UUID id) {
        return TenantDto.of(lifecycle.reactivate(new TenantId(id)));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Path("/{tenantId}/withdraw")
    public TenantDto withdraw(@PathParam("tenantId") UUID id, @Valid @NotNull TenantLifecycleRequest request) {
        return TenantDto.of(lifecycle.withdraw(new TenantId(id), request.reason()));
    }

    @GET
    @Path("/{tenantId}/usage")
    public TenantUsageDto usage(@PathParam("tenantId") UUID id) {
        return TenantUsageDto.of(usage.of(new TenantId(id)));
    }

    @GET
    @Path("/{tenantId}/usage/history")
    public TenantUsageHistoryDto usageHistory(@PathParam("tenantId") UUID id, @QueryParam("from") String from,
            @QueryParam("to") String to) {
        return TenantUsageHistoryDto.of(usageHistory.of(new TenantId(id), historyRange(from, to)));
    }

    /** Defaults: {@code to} = today (UTC), {@code from} = to - 89 days; at most 366 days, from <= to (else 400). */
    private UsageHistory.Range historyRange(String rawFrom, String rawTo) {
        LocalDate to = Params.date("to", rawTo).orElseGet(() -> LocalDate.now(clock.withZone(ZoneOffset.UTC)));
        LocalDate from = Params.date("from", rawFrom).orElse(to.minusDays(DEFAULT_HISTORY_DAYS - 1));
        if (from.isAfter(to)) {
            throw InvalidRequestException.of("from", "must not be after to");
        }
        if (ChronoUnit.DAYS.between(from, to) >= MAX_HISTORY_DAYS) {
            throw InvalidRequestException.of("from", "the range may span at most " + MAX_HISTORY_DAYS + " days");
        }
        return new UsageHistory.Range(from, to);
    }
}
