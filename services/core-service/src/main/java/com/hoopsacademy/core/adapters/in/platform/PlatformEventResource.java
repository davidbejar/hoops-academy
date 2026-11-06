package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.application.events.BackfillRosterEvents;
import jakarta.annotation.security.RolesAllowed;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Operations on core's roster events for platform super admins (WP81; no {@code X-Tenant-Id}). */
@Path("/platform/events")
@RolesAllowed(CallerIdentity.SUPER_ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class PlatformEventResource {

    /** Contract {@code EventBackfillRequest}; the body may be left out. */
    public record EventBackfillRequest(UUID tenantId, Boolean force) {}

    /** Contract {@code EventBackfill}. */
    public record EventBackfillDto(boolean force, int tenants, int failed, int appended,
            Map<String, Integer> appendedByTopic) {

        static EventBackfillDto of(BackfillRosterEvents.Result result) {
            return new EventBackfillDto(result.force(), result.tenants(), result.failed(), result.appended(),
                    result.appendedByTopic());
        }
    }

    private final BackfillRosterEvents backfill;

    public PlatformEventResource(BackfillRosterEvents backfill) {
        this.backfill = backfill;
    }

    @POST
    @Path("/backfill")
    @Consumes(MediaType.APPLICATION_JSON)
    public EventBackfillDto backfill(EventBackfillRequest request) {
        Optional<EventBackfillRequest> body = Optional.ofNullable(request);
        return EventBackfillDto.of(backfill.run(body.map(EventBackfillRequest::tenantId).map(TenantId::new),
                body.map(EventBackfillRequest::force).orElse(false)));
    }
}
