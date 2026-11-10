package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.application.platform.ListPlatformUsers;
import com.hoopsacademy.core.application.port.PlatformUsers;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** The application admin's Users area (WP91, decision 71): every login and its memberships, for super admins only. */
@Path("/platform/users")
@RolesAllowed(CallerIdentity.SUPER_ADMIN)
@Produces(MediaType.APPLICATION_JSON)
public class PlatformUserResource {

    /** Contract {@code PlatformUserMembership}. */
    public record PlatformUserMembershipDto(UUID tenantId, String tenantName, String tenantSlug, String tenantStatus,
            UUID personId, String givenName, String familyName, List<String> roles, boolean active) {

        static PlatformUserMembershipDto of(PlatformUsers.Membership membership) {
            return new PlatformUserMembershipDto(membership.tenant().value(), membership.tenantName(),
                    membership.tenantSlug(), membership.tenantStatus().name(), membership.person().value(),
                    membership.givenName(), membership.familyName(),
                    membership.roles().stream().sorted().map(Enum::name).toList(), membership.active());
        }
    }

    /** Contract {@code PlatformUser}. */
    public record PlatformUserDto(UUID id, String email, Instant createdAt,
            List<PlatformUserMembershipDto> memberships) {

        static PlatformUserDto of(PlatformUsers.Login login) {
            return new PlatformUserDto(login.id().value(), login.email().orElse(null), login.createdAt(),
                    login.memberships().stream().map(PlatformUserMembershipDto::of).toList());
        }
    }

    /** Contract {@code PlatformUserPage}. */
    public record PlatformUserPageDto(List<PlatformUserDto> items, PageMetaDto page) {}

    private final ListPlatformUsers users;

    public PlatformUserResource(ListPlatformUsers users) {
        this.users = users;
    }

    @GET
    public PlatformUserPageDto list(@QueryParam("q") @Size(min = 2, max = 100) String query,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        PageResult<PlatformUsers.Login> result = users.list(Optional.ofNullable(query), new PageRequest(page, size));
        return new PlatformUserPageDto(result.items().stream().map(PlatformUserDto::of).toList(),
                PageMetaDto.of(result));
    }
}
